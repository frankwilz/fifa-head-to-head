#!/usr/bin/env python3
"""Build the November 6 two-page report from frozen content and verified outputs.

Requires python-docx. Run from any working directory. The R pipeline remains
responsible for analysis; this script formats its saved outputs and manuscript.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent


def read_csv(path):
    with Path(path).open(newline='', encoding='utf-8') as stream:
        return list(csv.DictReader(stream))


def verify_snapshot():
    manifest = {r['key']: r['value'] for r in read_csv(ROOT / 'results/run-manifest.csv')}
    if manifest['cutoff'] != '2026-11-06':
        raise ValueError('This report requires the November 6 evidence snapshot.')
    for name in ['public_matches.csv', 'public_players.csv', 'public_earnings.csv',
                 'tournaments.csv', 'profile_attributes.csv']:
        actual = hashlib.md5((ROOT / 'data/raw' / name).read_bytes()).hexdigest()
        if actual != manifest['md5:' + name]:
            raise ValueError(f'Input and saved analysis disagree: {name}')
    metrics = next(r for r in read_csv(ROOT / 'results/metrics.csv') if r['scope'] == 'combined')
    expected = {'nodes': 81, 'matches': 129, 'win_edges': 124, 'played_edges': 122}
    for key, value in expected.items():
        if int(metrics[key]) != value:
            raise ValueError(f'Manuscript snapshot mismatch: {key}')
    correlations = read_csv(ROOT / 'results/correlations.csv')
    for comparison, n, rho in [('pagerank_vs_wins', 81, .970), ('pagerank_vs_earnings', 48, .287)]:
        row = next(r for r in correlations if r['scope'] == 'combined' and r['comparison'] == comparison)
        if int(row['n_complete']) != n or round(float(row['spearman_rho']), 3) != rho:
            raise ValueError(f'Manuscript correlation mismatch: {comparison}')
    sensitivity = next(r for r in read_csv(ROOT / 'results/major-tier-sensitivity/rank-correlations.csv')
                       if r['scope'] == 'combined')
    if int(sensitivity['n_complete']) != 38 or round(float(sensitivity['spearman_rho']), 3) != .976:
        raise ValueError('Sensitivity result and manuscript disagree.')
    rankings = [r for r in read_csv(ROOT / 'results/rankings.csv') if r['scope'] == 'combined']
    if [r['handle'] for r in rankings[:5]] != ['Shellzz', 'RvPLegend10', 'Nassada', 'Vejrgang', 'Ollelito']:
        raise ValueError('Leading player list and manuscript disagree.')


def set_font(style, name='Times New Roman', size=11):
    style.font.name = name
    style.font.size = Pt(size)
    style.font.color.rgb = RGBColor(0, 0, 0)
    rpr = style.element.get_or_add_rPr()
    fonts = rpr.find(qn('w:rFonts'))
    if fonts is None:
        fonts = OxmlElement('w:rFonts'); rpr.insert(0, fonts)
    for key in list(fonts.attrib):
        if 'theme' in key.lower(): del fonts.attrib[key]
    for key in ('ascii', 'hAnsi', 'eastAsia', 'cs'):
        fonts.set(qn('w:' + key), name)
    for tag in ('spacing','kern'):
        for node in list(rpr.findall(qn('w:'+tag))): rpr.remove(node)
    for node in list(style.element.findall('.//' + qn('w:pBdr'))): node.getparent().remove(node)


def add_hyperlink(paragraph, text, url):
    relation = paragraph.part.relate_to(url,
        'http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink', is_external=True)
    link = OxmlElement('w:hyperlink'); link.set(qn('r:id'), relation)
    run = OxmlElement('w:r'); props = OxmlElement('w:rPr')
    color = OxmlElement('w:color'); color.set(qn('w:val'), '000000'); props.append(color)
    underline = OxmlElement('w:u'); underline.set(qn('w:val'), 'single'); props.append(underline)
    run.append(props); value = OxmlElement('w:t'); value.text = text; run.append(value); link.append(run)
    paragraph._p.append(link)


def add_field(paragraph, instruction):
    field = OxmlElement('w:fldSimple')
    field.set(qn('w:instr'), instruction)
    value_run = OxmlElement('w:r'); value = OxmlElement('w:t'); value.text = '1'
    props = OxmlElement('w:rPr'); size = OxmlElement('w:sz'); size.set(qn('w:val'),'18'); props.append(size)
    value_run.append(props); value_run.append(value); field.append(value_run); paragraph._p.append(field)


def add_table(document, block):
    table = document.add_table(rows=1, cols=len(block['headers']))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    widths = block['widths']
    for column, width in zip(table.columns, widths): column.width=Inches(width)
    for cell, width in zip(table.rows[0].cells, widths): cell.width = Inches(width)
    for index, label in enumerate(block['headers']): table.rows[0].cells[index].text = label
    header = OxmlElement('w:tblHeader'); table.rows[0]._tr.get_or_add_trPr().append(header)
    for values in block['rows']:
        cells = table.add_row().cells
        for cell, value, width in zip(cells, values, widths):
            cell.text = value; cell.width = Inches(width)
    borders = OxmlElement('w:tblBorders')
    for edge in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
        border = OxmlElement('w:' + edge)
        for key, value in [('val','single'), ('sz','4'), ('color','D9D9D9')]: border.set(qn('w:' + key), value)
        borders.append(border)
    table._tbl.tblPr.append(borders)
    for row_index, row in enumerate(table.rows):
        row_prop = row._tr.get_or_add_trPr()
        no_split = OxmlElement('w:cantSplit'); row_prop.append(no_split)
        for col_index, cell in enumerate(row.cells):
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            properties = cell._tc.get_or_add_tcPr()
            margins = OxmlElement('w:tcMar')
            for edge in ('top','bottom','left','right'):
                item=OxmlElement('w:' + edge); item.set(qn('w:w'),'65' if edge in ('top','bottom') else '95'); item.set(qn('w:type'),'dxa'); margins.append(item)
            properties.append(margins)
            if row_index == 0:
                shade=OxmlElement('w:shd'); shade.set(qn('w:fill'),'F2F2F2'); properties.append(shade)
            for paragraph in cell.paragraphs:
                paragraph.style = document.styles['Table Body']
                paragraph.paragraph_format.keep_with_next = row_index == 0
                paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER if len(widths)==2 and widths[1] <= 2.1 and col_index==1 else WD_ALIGN_PARAGRAPH.LEFT
                for run in paragraph.runs: run.bold = row_index == 0
    gap=document.add_paragraph(); gap.paragraph_format.space_after=Pt(0); gap.paragraph_format.space_before=Pt(0)
    gap.paragraph_format.line_spacing=Pt(4); gap.add_run().font.size=Pt(4)


def markdown(data):
    lines = ['# ' + data['title'], '', data['subtitle'] + '  ' + data['date'], '',
             'Group members: ' + ' and '.join(data['authors']), '']
    for page in data['pages']:
        for block in page:
            kind=block['type']
            if kind.startswith('heading'): lines.extend(['## ' + block['text'], ''])
            elif kind=='table':
                lines.append('| ' + ' | '.join(block['headers']) + ' |')
                lines.append('| ' + ' | '.join(['---']*len(block['headers'])) + ' |')
                for row in block['rows']: lines.append('| ' + ' | '.join(row) + ' |')
                lines.append('')
            elif kind=='reference':
                lines.extend([''.join('['+r['text']+']('+r['url']+')' if 'url' in r else r['text'] for r in block['runs']), ''])
            elif kind=='caption': lines.extend(['**'+block['text']+'**',''])
            else: lines.extend([block['text'],''])
    return '\n'.join(lines)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--markdown', type=Path, default=HERE/'mid-project-report.md')
    parser.add_argument('--member-details', type=Path, help='Optional local map of author name to student number')
    args=parser.parse_args()
    verify_snapshot()
    data=json.loads((HERE/'nov-6-content.json').read_text())
    member_details=json.loads(args.member_details.read_text()) if args.member_details else {}
    doc=Document()
    section=doc.sections[0]
    section.page_width=Inches(8.5); section.page_height=Inches(11)
    section.left_margin=section.right_margin=Inches(1)
    section.top_margin=section.bottom_margin=Inches(.8)
    section.header_distance=section.footer_distance=Inches(.32)
    for name, size in [('Normal',11),('Title',17),('Subtitle',11),('Heading 1',12),('Heading 2',10.5),('Caption',10),('Footer',9)]:
        set_font(doc.styles[name],size=size)
    normal=doc.styles['Normal'].paragraph_format
    normal.space_after=Pt(5);normal.line_spacing=1.04;normal.widow_control=True
    for name in ('Heading 1','Heading 2'):
        doc.styles[name].font.bold=True
        fmt=doc.styles[name].paragraph_format
        fmt.space_before=Pt(8);fmt.space_after=Pt(4);fmt.keep_with_next=True
    doc.styles['Title'].font.bold=True
    doc.styles['Title'].paragraph_format.space_after=Pt(3)
    doc.styles['Subtitle'].font.italic=False
    doc.styles['Subtitle'].paragraph_format.space_after=Pt(3)
    for name, size, after in [('Report Note',9.5,4),('Reference',9.2,2),('Table Body',10.2,0)]:
        style=doc.styles.add_style(name,1);style.base_style=doc.styles['Normal'];set_font(style,size=size)
        style.paragraph_format.space_after=Pt(after);style.paragraph_format.line_spacing=1.0
    caption=doc.styles['Caption'];caption.font.italic=True
    caption.paragraph_format.space_before=Pt(2);caption.paragraph_format.space_after=Pt(3);caption.paragraph_format.keep_with_next=True
    p=doc.add_paragraph(data['title'],'Title')
    doc.add_paragraph(data['subtitle'] + '  ' + data['date'],'Subtitle')
    authors=[a + (f' ({member_details[a]})' if a in member_details else '') for a in data['authors']]
    p=doc.add_paragraph('Group members: ' + ' and '.join(authors));p.paragraph_format.space_after=Pt(6)
    for run in p.runs:run.font.size=Pt(10.5)
    for page_index,page in enumerate(data['pages']):
        for block_index,block in enumerate(page):
            kind=block['type']
            if kind in ('heading','heading_small'):
                p=doc.add_paragraph(block['text'],'Heading 1' if kind=='heading' else 'Heading 2')
                if page_index>0 and block_index==0:p.paragraph_format.page_break_before=True
            elif kind=='table':add_table(doc,block)
            elif kind=='reference':
                p=doc.add_paragraph(style='Reference')
                for run in block['runs']:
                    add_hyperlink(p,run['text'],run['url']) if 'url' in run else p.add_run(run['text'])
            else:doc.add_paragraph(block['text'], 'Caption' if kind=='caption' else 'Report Note' if kind=='note' else 'Normal')
    footer=section.footer.paragraphs[0];footer.alignment=WD_ALIGN_PARAGRAPH.RIGHT
    run=footer.add_run('Page ');run.font.size=Pt(9)
    add_field(footer,'PAGE');footer.add_run(' of ');add_field(footer,'NUMPAGES')
    for run in footer.runs:run.font.name='Times New Roman';run.font.size=Pt(9)
    doc.core_properties.title=data['title'];doc.core_properties.subject=data['subtitle'] + ' 6 November 2026'
    doc.core_properties.author=' and '.join(data['authors']);doc.core_properties.last_modified_by='Frank Williams'
    doc.core_properties.comments=''
    update = OxmlElement('w:updateFields'); update.set(qn('w:val'),'true'); doc.settings.element.append(update)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    doc.save(args.output)
    args.markdown.write_text(markdown(data))
    print('Created submission manuscript and editable report.')

if __name__=='__main__':main()
