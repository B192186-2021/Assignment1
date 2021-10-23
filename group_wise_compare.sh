#!/bin/bash
### USAGE: ./group_wise_compare <control_counts_mean1> <exam_counts_mean2>
### input files should have a fixed name format: ${smp}_${time}_${treatment}.output.txt
### generate "fold change" data for the "group-wise" comparisons
# set a flag to see if two input file are different
flag=0
# separate $smp $time $treatment from input string
f1=$1; f2=$2
smp1=${f1%%_*}; tmp=${f1%%.*}; treatment1=${tmp##*_}; tmp=${tmp#*_}; time1=${tmp%_*}
smp2=${f2%%_*}; tmp=${f2%%.*}; treatment2=${tmp##*_}; tmp=${tmp#*_}; time2=${tmp%_*}
# automatically decide the name of output
if [ $smp1 = $smp2 ];then o1=$smp1;else o1=${smp2}"VS"${smp1}; flag=1; fi
if [ $time1 = $time2 ];then o2=$time1;else o2=${time2}"VS"${time1}; flag=1; fi
if [ $treatment1 = $treatment2 ];then o3=$treatment1;else o3=${treatment2}"VS"${treatment1}; flag=1; fi
oname=$o1"_"$o2"_"$o3".groupwise.txt"
# To make sure that separation is successful
#echo $smp2 $time2 $treatment2 $oname
# judge if two input file are identical
if (($flag)); then
	# print the head for the output file
	printf "gene_ID\tdescreption\t${f1%%.*}\t${f2%%.*}\tfold_change\n" > ${oname}
    # calculate the fold change of genes between two groups
    paste $1 $2 | awk -F"\t" '{
    fc=($6 + 1)/($3 + 1);
    printf $1"\t"$2"\t"$3"\t"$6"\t%.2f\n",fc;
    }'| sort -t $'\t' -k 5rg,5 >> ${oname}
    # sort -t $'\t' means use tab as a seperator of file
fi
