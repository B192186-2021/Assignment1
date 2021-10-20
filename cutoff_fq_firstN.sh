#!/bin/bash

### USAGE: bash cutoff_fq_firstN.sh <number of base cut> <fq directory>
### cut off the first N bases of all reads in fastq files in target directory

for rawD in $(ls $2/*fq.gz) ; do
echo $rawD

fname_gz=${rawD##*/}
fname=${fname_gz:0:0-3}
echo $fname_gz $fname

done

