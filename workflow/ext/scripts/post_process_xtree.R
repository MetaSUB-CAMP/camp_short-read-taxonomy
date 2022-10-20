#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

covs = data.frame()
covsU = data.frame()
# covsR = data.frame()
files = dir(args[[1]],pattern = "*.cov")
for (file in files) {
  t = read.delim(paste(args[[1]],file,sep='/'),T,row=1,as.is=T)
  sname = gsub(".cov.*","",file)
  trimmed_names = character()
  for (n in rownames(t)) {
    trimmed_names = append(trimmed_names, strsplit(n, split = ' ')[[1]][1])
  }
  rownames(t) = trimmed_names
  covs[rownames(t),sname] = t[,"Proportion_covered"]
  covsU[rownames(t),sname] = t[,"Unique_proportion_covered"]
  #covsR[rownames(t),sname] = t[,"Reads_covered"]
}

covs[is.na(covs)]=0
covsU[is.na(covsU)]=0
# covsR[is.na(covsR)] = 0

otus = data.frame()
files = dir(args[[1]],pattern = "*.ref")
for (file in files) {
  tryCatch({
  t = read.delim(paste(args[[1]],file,sep='/'),F,row=1,as.is=T)
  },
  error=function(cond){
  print('No lines in file')
  })
  trimmed_names = character()
  for (n in rownames(t)) {
    trimmed_names = append(trimmed_names, strsplit(n, split = ' ')[[1]][1])
  }
  rownames(t) = trimmed_names
  otus[rownames(t),gsub(".ref.*","",file)] = t
}
otus[is.na(otus)]=0

# Prepare the coverage + ref cross-maps with taxonomy
tkey= read.delim(args[[7]],row=1,head=F,quote="")

taxaconv = make.unique(tkey[rownames(covs),1]) # Get taxonomy for all refs for which any coverage data exists
taxaconvR = make.unique(tkey[rownames(otus),1]) # ref-specific edition, so it can also be collapsed without needing same refs as cov table
# make.unique() appends sequence numbers to duplicated taxonomic IDs (common with new species)

orig.abund = colSums(otus)

thres = as.numeric(args[[2]]) # min thres to retain a genome
hthres = as.numeric(args[[3]]) # min thres to guarantee a genome is present
uthres = as.numeric(args[[4]]) # min unique coverage to retain a genome

mask = (covsU <= uthres | covs <= thres) & covs <= hthres # Reference genome coverages that fall below the thresholds
unmasked = 0+!mask    # Reference genome coverages that are sufficiently large
# unmasked = rowsum(0+!mask,taxaconv)
rownames(unmasked) = taxaconv

tax.tm = data.frame(otus)
# tax.tm = rowsum(otus,taxaconvR)
rownames(tax.tm) = taxaconvR
tax.tm = tax.tm[rownames(tax.tm) %in% rownames(unmasked),,drop = FALSE]
# tax.tm[!unmasked[rownames(tax.tm),]]=0 
tax.tm = tax.tm[rowSums(tax.tm) > 0,,drop = FALSE]
tax.tm["Unknown",]=orig.abund - colSums(tax.tm)

tax.cm = data.frame(otus)
rownames(tax.cm) = taxaconvR
tax.cm = tax.cm[rownames(tax.tm)[-nrow(tax.tm)],,drop = FALSE]
# tax.cm = cbind(otus,taxaconvR)[rownames(tax.tm)[-nrow(tax.tm)],]
write.table(tax.tm,paste(args[[5]],'/',args[[6]],'_counts.tsv',sep=''),F,F,'\t')
write.table(tax.cm,paste(args[[5]],'/',args[[6]],'_counts_raw.tsv',sep=''),F,F,'\t')

tax.tm.ra = sweep(tax.tm,2,colSums(tax.tm),'/')
tax.cm.ra = sweep(tax.cm,2,colSums(tax.cm),'/')

write.table(tax.tm.ra,paste(args[[5]],'/',args[[6]],'_ra.tsv',sep=''),F,F,'\t')
write.table(tax.cm.ra,paste(args[[5]],'/',args[[6]],'_ra_raw.tsv',sep=''),F,F,'\t')

write.table(covs,paste(args[[5]],'/',args[[6]],'_coverages.tsv',sep=''),F,F,'\t')
write.table(covsU,paste(args[[5]],'/',args[[6]],'_unique_coverages.tsv',sep=''),F,F,'\t')












