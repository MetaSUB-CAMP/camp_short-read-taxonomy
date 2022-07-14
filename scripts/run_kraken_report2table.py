#! /usr/bin/env python3
#  Jan 13, 2022
#  Parse kraken2 reports, 
#  showing taxa above certain abundance threshold,
#  and appending domain name 

#  April 13, 2022
#  Updated to include fungi (=kingdom)

import gzip
import sys
import os
import re

report    = sys.argv[1]
threshold = sys.argv[2]
taxlevel  = sys.argv[3]
sample = report.split('/')[-1].split('.')[0]
domain = "root"
with open('krakenReportClean.threshold'+threshold+'.taxlevel'+taxlevel+'.'+sample+'.tsv', 'w') as outfile:
	outfile.write('domain,taxon,taxonID,numReadsClade,numReadsDirect,pct\n')
	with gzip.open(report, 'rt') as infile:
		for line in infile:
			line = line.strip()
			line = re.sub('\s\s+', '\t', line)
			pct, numreadsClade, numreadsDirect, rank, taxID, taxon = line.split('\t')
			taxon = taxon.replace(',','')
			
			# get domain
			if rank == "D" or rank == "K":
				domain = taxon
			
			# check abundance
			threshold = float(threshold)
			pct = float(pct)
			if rank == taxlevel and pct >= threshold:
				outfile.write(domain+','+taxon+','+taxID+','+numreadsClade+','+numreadsDirect+','+str(pct)+'\n')
				
				
