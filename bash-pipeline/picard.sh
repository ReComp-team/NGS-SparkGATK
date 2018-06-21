#! /bin/bash
#$ -cwd
#$ -j y
#$ -l h="node1[7-9]"
#$ -pe smp 4

source /etc/profile.d/modules.sh
module load apps/samtools/0.1.18/gcc-4.4.6
module load apps/picard/1.85/noarch

cwd=`pwd`; export cwd

if [ $# -lt 6 ] ; then
	echo '['`date`']: Not enough arguments' | tee -a $RUNNING_INFO_FILE
	exit 1
fi

SAMPLE_ID=$1
SAMPLE_PATH=$2
REF_DIR=$3
SCRATCH_DIR=$4
RUNNING_INFO_FILE=$5
READ_GROUP_ID=$6

echo "[" `date` "]: $0 started."

#INDIR="${SAMPLE_PATH}/${SAMPLE_ID}"
#INDIR=$SAMPLE_PATH
INDIR=`dirname $RUNNING_INFO_FILE`
WRKGDIR="${SCRATCH_DIR}/${SAMPLE_ID}.GATKpipe.picard"
OUTDIR="${INDIR}"
#OUTDIR=`dirname $RUNNING_INFO_FILE`
REF_FILE="${REF_DIR}/ucsc.hg19.YAOBO.fasta"

echo '['`date`']:''Making working directory on ' $HOSTNAME '. ' >> $RUNNING_INFO_FILE
echo '['`date`']:''Working directory on ' $WRKGDIR '. ' >> $RUNNING_INFO_FILE
echo '' >> $RUNNING_INFO_FILE

mkdir -p $WRKGDIR

SORTED_BAM_FILE="$OUTDIR/bwa/${SAMPLE_ID}.sorted.bam"

echo '['`date`']:''Making picard directory: ' $PICARD_OUTDIR >> ${RUNNING_INFO_FILE}
# Picard Remove Duplicates (ADD THIS STAGE!!)
PICARD_OUTDIR="$OUTDIR/picard"
SORTED_BAM_FILE_CLEANED="$WRKGDIR/${SAMPLE_ID}_cleaned.sorted.bam"
SORTED_BAM_FILE_NODUPS_NO_RG="$WRKGDIR/${SAMPLE_ID}_nodups_no_RG.sorted.bam"
SORTED_BAM_FILE_NODUPS="$PICARD_OUTDIR/${SAMPLE_ID}_nodups.sorted.bam"
SORTED_INDX_FILE_NODUPS="${SORTED_BAM_FILE_NODUPS}.bai"
PICARD_LOG="$PICARD_OUTDIR/${SAMPLE_ID}_picard.log"
PICARD_TEMP="$WRKGDIR/Picard_Temp"

Picard_nodups="java -jar $PICARDDIR/java/MarkDuplicates.jar VALIDATION_STRINGENCY=LENIENT"
Picard_addRG="java -jar $PICARDDIR/java/AddOrReplaceReadGroups.jar VALIDATION_STRINGENCY=LENIENT"
Picard_CleanSam="java -jar $PICARDDIR/java/CleanSam.jar VALIDATION_STRINGENCY=LENIENT"
mkdir -p $PICARD_OUTDIR

echo '['`date`']:''Making temporary directory '$PICARD_TEMP' for PICARD..' >> ${RUNNING_INFO_FILE}
mkdir -p $PICARD_TEMP
echo '['`date`']:''Starting PICARD to cleaning bam files...' >> ${RUNNING_INFO_FILE}
$Picard_CleanSam INPUT=$SORTED_BAM_FILE OUTPUT=$SORTED_BAM_FILE_CLEANED
echo '['`date`']:''Done!' >> ${RUNNING_INFO_FILE}
echo '['`date`']:''Starting PICARD to remove duplicates...' >> ${RUNNING_INFO_FILE}
$Picard_nodups INPUT=$SORTED_BAM_FILE_CLEANED OUTPUT=$SORTED_BAM_FILE_NODUPS_NO_RG METRICS_FILE=$PICARD_LOG REMOVE_DUPLICATES=true ASSUME_SORTED=true TMP_DIR=$PICARD_TEMP
echo '['`date`']:''Done!' >> ${RUNNING_INFO_FILE}
echo '['`date`']:''Adding read group information to bam file...' >> ${RUNNING_INFO_FILE}
$Picard_addRG INPUT=$SORTED_BAM_FILE_NODUPS_NO_RG OUTPUT=$SORTED_BAM_FILE_NODUPS RGID=$READ_GROUP_ID RGPL=illumina RGSM=$SAMPLE_ID RGLB="${SAMPLE_ID}_${READ_GROUP_ID}" RGPU="platform_Unit_${SAMPLE_ID}_${READ_GROUP_ID}"
rm $SORTED_BAM_FILE_CLEANED
rm $SORTED_BAM_FILE_NODUPS_NO_RG
echo '['`date`']:''Done! Bam file without reading group info is removed.' >> ${RUNNING_INFO_FILE}
rm -r $PICARD_TEMP
echo '['`date`']:''Temporary directory is removed.' >> ${RUNNING_INFO_FILE}
echo '' >> ${RUNNING_INFO_FILE}

echo '['`date`']:''Indexing bam files...' >> ${RUNNING_INFO_FILE}
samtools index $SORTED_BAM_FILE_NODUPS
echo '['`date`']:''Done.' >> ${RUNNING_INFO_FILE}
echo '' >> ${RUNNING_INFO_FILE}

################### cleaning bit #########################################
rm -r $WRKGDIR
echo '['`date`']:''Directory ' $WRKGDIR ' is removed from ' $HOSTNAME '.' >> ${RUNNING_INFO_FILE}
echo '['`date`']:''Picard is done.' >> ${RUNNING_INFO_FILE}
echo "[" `date` "]: Picard job has completed."

