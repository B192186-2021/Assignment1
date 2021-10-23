#!/bin/bash

### USAGE: ./pipeline.sh [num_of_threads] [cut_off_bps] [NEW_data_directory] [NEW_reference] [NEW_bedfile]

################################### Manualy Configuration ##################################
# defalt number of threads for this script
thread=8
### initialize the defalt path for input data
# directory containing the pair-end RNAseq raw reads data
dataD="/localdisk/data/BPSM/AY21/fastq"
# reference genome in fasta.gz format
ref="/localdisk/data/BPSM/AY21/Tcongo_genome/TriTrypDB-46_TcongolenseIL3000_2019_Genome.fasta.gz"
# bedfile containing annotation data
ann="/localdisk/data/BPSM/AY21/TriTrypDB-46_TcongolenseIL3000_2019.bed"
# number of bps in raw data that need to be cut off
cutbp=0

####################################### Preperation ########################################
# if the paths are updated to different files or directories
if [ -n "$3" ]; then
{
    dataD=$3;
    # delete the '/' tail if there is one from the input
    if [ ${dataD:0-1} = '/' ];then dataD=${dataD:0:0-1}; fi
}
fi
echo "raw data: "$dataD;
if [ -n "$4" ]; then ref=$4; fi
if [ -n "$5" ]; then ann=$5; fi
# if a different thread number are specified
if [ -n "$1" ]; then thread=$1; fi
# if number of bps in raw data that need to be cut off has been specified
if [ -n "$2" ]; then cutbp=$2; fi
echo "ref:      "$ref
echo "bedfile:  "$ann
echo "threads:  "$thread
echo "cutbp:    "$cutbp

###################################### Quality checking ####################################
# copy the reference data to the present directory
mkdir ref
cp $ref ./ref/TriTrypDB-46_TcongolenseIL3000_2019_Genome.fasta.gz
# quality check
fastqc -o ./fastqc/ -t $thread -q ${dataD}/100k.*.fq.gz
# data cleaning (roughly cut off the first 10 bases of all gz reads
bash ./cutoff_fq_firstN.sh $cutbp $dataD $thread
# quality check again
fastqc -o ./fastqc/ -t $thread -q ./data_clean/*clean.fq.gz 
# generate a overall summary for fastqc output (before and after clean)
bash ./summary_extraction.sh

##################################### Reads mapping ########################################
# generate a directory for mapping to avoid being messy
mkdir mapping
cd mapping
# build the index for the reference genome, silently
bowtie2-build --threads $thread ../ref/TriTrypDB-46_TcongolenseIL3000_2019_Genome.fasta.gz TcongolenseIL3000 > bowtie2-build.log
# get the list of sample
for i in $(ls ../data_clean/*fq.gz);do fname=${i##*/}; ftag=${fname%_*}; echo ${ftag}; done | sort -u > sample_list.xls
# run the bowtie2 in batch
for smp in $(cat sample_list.xls);do
    echo "Mapping for $smp started"
    bowtie2 -p $thread --no-unal -x TcongolenseIL3000 -1 ../data_clean/${smp}_1.clean.fq.gz -2 ../data_clean/${smp}_2.clean.fq.gz 2>${smp}.bowtie2.log | samtools sort -O bam -@ $thread > ${smp}_sorted.bam 
    # generate the index for the bam-file
    samtools index -@ $thread ${smp}_sorted.bam
done

######################################## Counting ##########################################
t=1   # initialization
for smp in $(cat sample_list.xls);do
{
    # bedtools cannot use multicore parameter, whilst we could make it via bash
    if (( $t < $thread ));then
    	t=$[ $t + 1 ]   # add 1 to $t
    else
    	t=1
    	wait
    fi
    # generate count data with bedtools, keep it running in the background
    {
    	bedtools multicov -bams ${smp}_sorted.bam -bed ${ann} > ${smp}.count
    }&
}
done

################################## Generate output files ###################################
# move to Outputs directory
mkdir ../Outputs
cd ../Outputs
# generate a list to gather replications runs into proper groups
# in sample_groups.xls, field 1 is sample name, field 2 is time, 
# field 3 is treatment, field n>3 are runs ID
sed '1d' /localdisk/data/BPSM/AY21/fastq/100k.fqfiles | \
sort -t $'\t' -k 2,2 -k 4n,4 -k 5,5 -k 3n,3 | \
awk 'BEGIN{FS="\t"; smp=""; time=""; treatment=""}{
	if($2 != smp || $4 != time || $5 != treatment){
		printf "\n"$2"\t"$4"\t"$5"\t"$1;
		smp=$2; time=$4; treatment=$5;
	}else{
		printf "\t"$1;
	}
}' > sample_groups.xls
# remove the blank line on top of the file and save the file
sed -i '1d' sample_groups.xls
# after running bedtools, all count files are in same gene order, 
# so it's ok to paste data directly
while read smp time treatment runs; do
    # initialization of a empty text file
    printf "" > counts.tmp
    for run_name in ${runs};do
    	cut -f6 ../mapping/*${run_name}.count | paste counts.tmp - > counts1.tmp
    	mv counts1.tmp counts.tmp
    done
    # calculate the mean, keep two significant digits
    cut -f2- counts.tmp | awk '{
    	n=0; sum=0;
    	for(i=1;i<=NF;i++){
    		n=n+1;
    		sum=sum+$i
    	}
    	mean=sum/n
    	printf "%.2f\n",mean
    }' > means.tmp
    # paste the gene information with the mean of counts
    cut -f4,5 ../mapping/*${run_name}.count | paste - means.tmp > ${smp}_${time}_${treatment}.output.txt
done <  sample_groups.xls
# clean the garbage(temporary files)
rm means.tmp counts.tmp
