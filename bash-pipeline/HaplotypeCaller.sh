#! /bin/bash
#$ -cwd
#$ -j y

source /users/njc97/scripts/Yaobo/Common.sh
echo "[" `date` "]: $0 started."

##### Need to change the scala script path accordingly at line 20

#BAM_LIST_FILE="/users/a5907529/lustre/Kidney_20130211/HaplotypeCaller_oldOnes_A1569_A1982_A1671b1b2/BamFile.list"
BAM_LIST_FILE="$OUTPUT_PATH/ReducedBamFile.list"

# Path to the file that lists all bam files pahts of samples 
SCATTER_NUMBER="25"
# How many sub jobs you want split
#OUTPUT_FILE="/users/a5907529/lustre/Kidney_20130211/HaplotypeCaller_oldOnes_A1569_A1982_A1671b1b2/HaplotyperCaller.vcf"
OUTPUT_FILE="$OUTPUT_PATH/variants/HaplotypeCaller_All.vcf"

#TEMP_DIR="/users/a5907529/lustre/Kidney_20130211/HaplotypeCaller_oldOnes_A1569_A1982_A1671b1b2/HaplotypeCaller_tmp"
TEMP_DIR="$OUTPUT_PATH/variants/HaplotypeCaller_tmp"

mkdir -p $TEMP_DIR

REF_FILE="$REF_DIR/ucsc.hg19.YAOBO.fasta"

#module load apps/gatkqueue/2.6.4/noarch
module load apps/gatkqueue/2.8.1/noarch

java -Djava.io.tmpdir=$TEMP_DIR -Xmx8g -Xms8g -jar $GATKQUEUEDIR/Queue.jar -S HaplotypeCaller.scala -I $BAM_LIST_FILE -R $REF_FILE -sg $SCATTER_NUMBER -jobRunner GridEngine -jobPriority 1 -jobResReq "h=node1[7-9]" -V_out $OUTPUT_FILE -retry 2 -run

rm -r $TEMP_DIR

echo "[" `date` "]: $0 has completed."
