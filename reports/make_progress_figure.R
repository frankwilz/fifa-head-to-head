# Compact versions of the existing played-network and earnings figures.
# Uses the saved November 6 outputs; no analyses or data are changed.
library(igraph)
r <- read.csv("results/rankings.csv",stringsAsFactors=FALSE)
r <- r[r$scope=="combined",,drop=FALSE]
g <- read_graph("results/graphs/combined-played.graphml",format="graphml")
set.seed(20261104)
xy <- layout_with_fr(g,weights=NA)
pr <- r$pagerank[match(V(g)$name,r$player_id)]
labels <- ifelse(V(g)$name %in% r$player_id[r$pagerank_rank<=2],V(g)$handle,NA)
png("reports/figures/progress-evidence.png",width=6.5,height=2.12,units="in",res=400)
par(mfrow=c(1,2),family="serif",ps=9,oma=c(0,0,0,0))
par(mar=c(.25,.25,1.7,.2))
plot(g,layout=xy,vertex.label=labels,vertex.label.cex=.92,vertex.label.color="#102e38",
     vertex.label.dist=1.6,vertex.size=2+5.8*sqrt(pr/max(pr)),
     vertex.color="#a9d7df",vertex.frame.color="#147d92",edge.color="#93a6b2",edge.width=.65,
     main="A  Observed played network")
par(mar=c(3.05,3.4,1.7,.45),mgp=c(1.9,.55,0),tcl=-.2)
m <- r[is.finite(r$earnings_usd),,drop=FALSE]
plot(m$earnings_usd,m$pagerank,log="x",pch=19,cex=.58,col="#147d92",
     xaxt="n",xlim=c(1000,1100000),ylim=c(0,.115),
     xlab="Recorded earnings in USD (log scale)",ylab="Win-network PageRank",
     main="B  PageRank and recorded earnings")
axis(1,at=c(1000,10000,100000,1000000),labels=c("1k","10k","100k","1m"))
leaders <- which(m$pagerank_rank<=2)
text(m$earnings_usd[leaders],m$pagerank[leaders],labels=m$handle[leaders],pos=3,cex=.9)
dev.off()
