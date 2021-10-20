#!/bin/bash

### USAGE: ./workflow.sh [multi_threads] [NEW_data_directory] [NEW_reference] [NEW_bedfile]

################################## Manualy Configuration ########################################
# defalt threads for this script is 4
thread=4

### initialize the defalt path for input data

# directory containing the pair-end RNAseq raw reads data 
dataD="/localdisk/data/BPSM/AY21/fastq"

# reference genome in fasta.gz format
ref="/localdisk/data/BPSM/AY21/Tcongo_genome/TriTrypDB-46_TcongolenseIL3000_2019_Genome.fasta.gz"

# bedfile containing annotation data
ann="/localdisk/data/BPSM/AY21/TriTrypDB-46_TcongolenseIL3000_2019.bed"

####################################### Preperation ##############################################
# if these paths are updated to different files or directories
if [ -n "$2" ]; then 
{
dataD=$2;
# delete the '/' tail
if [ ${dataD:0-1} = '/' ];then dataD=${dataD:0:0-1}; fi
echo "directory containing the pair-end RNAseq raw data: "$dataD; 
}
fi

if [ -n "$3" ]; then ref=$3; echo "ref = "$3; fi
if [ -n "$4" ]; then ann=$4; echo "annotation = "$4; fi

# if a different thread number are specified
if [ -n "$1" ]; then thread=$1; echo "thread="$1; fi
##################################################################################################

# copy the reference data to the present directory
mkdir ref
cp $ref ref/
echo $dataD $ref $ann

