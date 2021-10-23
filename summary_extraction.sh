#!/bin/bash

### extract summary from the outputs of fastqc
### and give a overall summary for that

# initialization
printf "\nDetails:\n" > qc_summary.tmp
echo "Counts:" > qc_scount.tmp

for zipf in $(ls ./fastqc/*fastqc.zip);do
	unzip -jp $zipf ${zipf:9:0-4}/summary.txt >> ./qc_summary.tmp
done

for assessment in "FAIL" "WARN" "PASS";do
	printf ${assessment}" before clean: " >> qc_scount.tmp
	grep ${assessment} qc_summary.tmp | grep -v "clean" | wc -l >> qc_scount.tmp
	printf ${assessment}" after clean: " >> qc_scount.tmp
	grep ${assessment} qc_summary.tmp | grep "clean" | wc -l >> qc_scount.tmp
done

cat qc_scount.tmp qc_summary.tmp > qc_summary_overall.txt
rm qc*.tmp
