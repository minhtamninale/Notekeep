#!/bin/bash

# $1 : input file
# $2 : chrom.sizes
# $3 : cluster size lower bound
# $4 : cluster size upper bound
# $5 : output file prefix

set -euxo pipefail

INPUT_CLUSTERS=$1
CHROMSIZES=$2
MINSIZE=$3
MAXSIZE=$4
OPREFIX=$5


zcat $INPUT_CLUSTERS \
    | cut -f 2- \
    | python <(cat <<EOF
from itertools import combinations
import fileinput
for line in fileinput.input():
    size = line.count('DNA')
    if size >=$MINSIZE and size <= $MAXSIZE:
        reads = [dna_read for dna_read in line.strip().split('\t') if 'DNA' in dna_read]
        coords = [coord.split('_')[1].split('-')[0] for coord in reads]
        chrom_coords = [coord.replace(':', '\t') for coord in coords]
        pairs = list(combinations(chrom_coords, 2))
        score = 2.0 / size
        for a, b in pairs:
            print(a, b, score, sep='\t')
EOF
)  \
   | cooler cload pairs \
        -c1 1 -p1 2 -c2 3 -p2 4 \
        --zero-based --chunksize 10000000 --field count=5:dtype=float32 \
        $CHROMSIZES:1000 - "${OPREFIX}.${MINSIZE}-${MAXSIZE}.norm_n2.1000.cool"














