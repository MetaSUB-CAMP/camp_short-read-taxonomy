#!/bin/bash

/path/to/xtree --threads 20 --redistribute \
    --seqs ${1} \
    --db ${2} \
    --ref-out ${3}.ref \
    --cov-out ${3}.cov 

cp ${3}.ref ../${4}.ref
cp ${3}.cov ../${4}.cov

