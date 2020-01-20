#! /bin/bash

echo $HOSTNAME

echo `date +%Y-%B-%d-%T`

start=$SECONDS

#Install the following tools:
# conda install -y -c conda-forge -c bioconda -c defaults canu;conda install -y -c bioconda kmer-jellyfish; \
# conda install -y -c bioconda wtdbg;conda install -y -c bioconda assembly-stats;conda install -y -c biobuilds breakdancer; \
# conda install -c bioconda scalpel;conda install -c bioconda sniffles;conda install -y -c bioconda scalpel;conda install -c bioconda unicycler; \
# conda install -y kleborate;conda install -y velvet

cd /home/gunz/2020-repos/2-assembly/

# mkdir -p raw-reads/{1-illumina,2-pacbio};mkdir -p results/{1-illumina,2-pacbio}

for sample in `cat list.txt`;
do 
 	R1=raw-reads/1-illumina/${sample}_1.fastq
 	R2=raw-reads/1-illumina/${sample}_2.fastq

 	echo "Processing sample: "$sample

#DENOVO ASSEMBLY USING VELVETH SUITE
#Running assembly for different k-mer sizes [29,19,15] #Note k=mer size 11 is too small, software crashes after somewhere so try 15
velveth results/1-illumina/k.assembly.29 29 -shortPaired -fastq -separate $R1 $R2
velveth results/1-illumina/k.assembly.19 19 -shortPaired -fastq -separate $R1 $R2
velveth results/1-illumina/k.assembly.11 15 -shortPaired -fastq -separate $R1 $R2

#Now using velvetg for: de Bruijn graph construction, error removal and repeat resolution
velvetg results/1-illumina/k.assembly.29 -exp_cov auto -ins_length 350
velvetg results/1-illumina/k.assembly.19 -exp_cov auto -ins_length 350
velvetg results/1-illumina/k.assembly.15 -exp_cov auto -ins_length 350

#Some other parameters to try out
velvetg results/1-illumina/k.assembly.29 -exp_cov auto -ins_length 350 -min_contig_lgth 200 -cov_cutoff 5
velvetg results/1-illumina/k.assembly.15 -exp_cov auto -ins_length 350 -min_contig_lgth 200 -cov_cutoff 5

#Getting assembly stats for the different k-mer sizes
assembly-stats -t results/1-illumina/k.*/*.fa

# To get the statistic for the contigs, rather than supercontigs, you can use following command:
seqtk cutN -n1 results/1-illumina/k.*/contigs.fa > results/1-illumina/tmp.contigs.fasta
assembly-stats -t results/1-illumina/tmp*
 
end=$SECONDS

echo "Your run took approximately $((end-start)) seconds"

done


#NOW PACBIO ASSEMBLY

echo $HOSTNAME

echo `date +%Y-%B-%d-%T`

start=$SECONDS

cd /home/gunz/2020-repos/2-assembly/
mkdir -p results/2-pacbio/fastqc-stats
# mkdir -p results/2-pacbio/wtdbg
for sample in `cat list2.txt`;
do 
 	R1=raw-reads/2-pacbio/${sample}.fastq
#  	R2=raw-reads/1-illumina/${sample}_2.fastq [No $R2 because pacbio produces single reads]

 	echo "Processing sample: "$sample
    mkdir results/2-pacbio/fastqc-stats/${sample}
    fastqc $R1 --outdir results/2-pacbio/fastqc-stats/${sample}
#     mkdir -p results/2-pacbio/wtdbg/${sample}
    canu -p PB -d results/2-pacbio/Pacbio_${sample} -s file.specs -pacbio-raw $R1 > canu_output.txt
    
    assembly-stats -t results/2-pacbio/Pacbio_${sample}/PB*.contig.fasta
    
#Another long read assembler based on de Bruijn graphs is “wtdbg"
#     wtdbg2 -t6 -i raw-reads/2-pacbio/PBReads.fastq -o results/2-pacbio/wtdbg
#     wtdbg2 -t6 -i $R1 -o results/2-pacbio/wtdbg/${sample}_wtdbg
#     wtpoa-cns -t6 -i results/2-pacbio/wtdbg/${sample}/wtdbg*.lay.gz -fo results/2-pacbio/wtdbg/${sample}/wtdbg.ctg.lay.fa
#     assembly-stats results/2-pacbio/wtdbg/${sample}/wtdbg.ctg.lay.fa

 end=$SECONDS

echo "Your run took approximately $((end-start)) seconds"

done