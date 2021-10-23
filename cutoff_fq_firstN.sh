#!/bin/bash

### USAGE: ./cutoff_fq_firstN.sh <number of base cut + 1> <fq directory> <num_of_threads>
### cut off the first N bases of all reads in fastq files in target directory

mkdir data_clean
t=1  #number of threads running now
for rawD in $(ls $2/*fq.gz) ; do
{
if (( $t < $3 ));then
t=$[ $t + 1 ]
else
t=1
wait
fi
{
fname_gz=${rawD##*/}
fname=${fname_gz:0:0-6}
echo "start to clean ${fname}.fq"
gzip -c -d $rawD | awk -v cnum="$1" 'BEGIN{n=1}{
if(n>4){n=n-4}
# Is this line a fastq read header or the third line
if(n==1 || n==3){print $0;}
# so this line should be the sequence or its score
else{print substr($0,cnum);}
n=n+1
}' > ./data_clean/${fname}.clean.fq
gzip -f ./data_clean/${fname}.clean.fq
}&
}
done
