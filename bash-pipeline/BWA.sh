#! /bin/bash
#$ -cwd
#$ -j y
#$ -l h="node1[7-9]"
#$ -pe smp 4

###$ -q smp.q@node17,smp.q@node18,smp.q@node19,smp.q@node20
##$ -l bigscratch=1

### Adjust the perl script detectSampleLanes.pl accordingly

source /etc/profile.d/modules.sh
module load apps/samtools/0.1.18/gcc-4.4.6
#module load apps/bwa/0.7.4/gcc-4.4.6

export PATH=$PATH:/users/njc97/apps/bwa/bwa-0.7.5a

cwd=`pwd`; export cwd

SAMPLE_ID=$1
SAMPLE_PATH=$2
REF_DIR=$3
SCRATCH_DIR=$4
RUNNING_INFO_FILE=$5

echo "[" `date` "]: $0 args:"
echo SAMPLE_ID=$1
echo SAMPLE_PATH=$2
echo REF_DIR=$3
echo SCRATCH_DIR=$4
echo RUNNING_INFO_FILE=$5

SCRIPTS_DIR="/users/njc97/scripts/Yaobo"
source $SCRIPTS_DIR/Common.sh

#INDIR="${SAMPLE_PATH}/${SAMPLE_ID}"
INDIR=$SAMPLE_PATH
WRKGDIR="${SCRATCH_DIR}/${SAMPLE_ID}.GATKpipe.bwa"
#OUTDIR="${INDIR}/bwa"
OUTDIR=`dirname $RUNNING_INFO_FILE`
OUTDIR=${OUTDIR}/bwa
REF_FILE="${REF_DIR}/ucsc.hg19.YAOBO.fasta"
DBSNP_VCF="${REF_DIR}/dbsnp_138.hg19.YAOBO.vcf"

echo '['`date`']:''Making working directory on ' $HOSTNAME '. ' >> $RUNNING_INFO_FILE
echo '['`date`']:''Working directory on ' $WRKGDIR '. ' >> $RUNNING_INFO_FILE
echo '' >> $RUNNING_INFO_FILE

mkdir -p $WRKGDIR

################## BWA Bit ##################################

echo '['`date`']:''Making dir for BWA and start the alignment... ' >> $RUNNING_INFO_FILE
mkdir -p $OUTDIR

echo perl $SCRIPTS_DIR/detectSampleLanes.pl $SAMPLE_PATH $SAMPLE_ID
LANES_STRING=`perl $SCRIPTS_DIR/detectSampleLanes.pl $SAMPLE_PATH $SAMPLE_ID`
check_exit_code

echo "Lanes string: $LANES_STRING"
LANES=($LANES_STRING)

BAM_FILE_LIST=""
echo "loop"
for LANE in "${LANES[@]}"
do
	SAM_FILE1="$WRKGDIR/${SAMPLE_ID}_${LANE}.sam"
	BAM_FILE1="$WRKGDIR/${SAMPLE_ID}_${LANE}.bam"
        CLEANNING_STAGE_1="$CLEANNING_STAGE_1 $BAM_FILE1"
	BAM_FILE_LIST="${BAM_FILE1} $BAM_FILE_LIST"
	SAI_FILE1_1="$WRKGDIR/${SAMPLE_ID}_${LANE}_1.sai"
	SAI_FILE1_2="$WRKGDIR/${SAMPLE_ID}_${LANE}_2.sai"  
#	READ_FILE1="$INDIR/${SAMPLE_ID}_L00${LANE}_1.trimmed.fastq.polyN_removed.txt_val_1.fq"
#	READ_FILE2="$INDIR/${SAMPLE_ID}_L00${LANE}_2.trimmed.fastq.polyN_removed.txt_val_2.fq"
#	READ_FILE1="$INDIR/${SAMPLE_ID}_1_sequence.txt"
#	READ_FILE2="$INDIR/${SAMPLE_ID}_2_sequence.txt"
        READ_FILE1="$INDIR/${SAMPLE_ID}_L${LANE}_R1_001.fastq"
        READ_FILE2="$INDIR/${SAMPLE_ID}_L${LANE}_R2_001.fastq"

        # Check input file 1
        if [ ! -f ${READ_FILE1} ]; then
          echo Input file $READ_FILE1 missing
          if [ -f "${READ_FILE1}.gz" ]; then
            echo "Found gzipped version; uncompressing..."
            FILE=`basename $READ_FILE1`
            UNGZ_FILE="$WRKGDIR/${FILE}"
            gunzip -c "${READ_FILE1}.gz" > $UNGZ_FILE
            READ_FILE1=$UNGZ_FILE
            CLEANNING_STAGE_1="$CLEANNING_STAGE_1 $UNGZ_FILE"
          else
            echo "Cannot find input file $READ_FILE1"
            exit 1
          fi
        fi
        #Check input file 2
        if [ ! -f ${READ_FILE2} ]; then
          echo Input file $READ_FILE2 missing
          if [ -f "${READ_FILE2}.gz" ]; then
            echo "Found gzipped version; uncompressing..."
            FILE=`basename $READ_FILE2`
            UNGZ_FILE="$WRKGDIR/${FILE}"
            gunzip -c "${READ_FILE2}.gz" > $UNGZ_FILE
            READ_FILE2=$UNGZ_FILE
            CLEANNING_STAGE_1="$CLEANNING_STAGE_1 $UNGZ_FILE"
          else
            echo "Cannot find input file $READ_FILE2"
            exit 1
          fi
        fi

	#Let's use mem instead of aln+sampe
	#bwa aln -t 2 $REF_FILE $READ_FILE1 > $SAI_FILE1_1
	#bwa aln -t 2 $REF_FILE $READ_FILE2 > $SAI_FILE1_2
	#bwa sampe $REF_FILE $SAI_FILE1_1 $SAI_FILE1_2 $READ_FILE1 $READ_FILE2 > $SAM_FILE1
	bwa mem -t 8 -M $REF_FILE $READ_FILE1 $READ_FILE2 > $SAM_FILE1
	samtools import $REF_FILE $SAM_FILE1 $BAM_FILE1
	
	#Clean out large files from scratch
	####rm -f $SAM_FILE1 $SAI_FILE1_1 $SAI_FILE1_2
done
echo "loop done"
echo "BAM files = ${BAM_FILE_LIST}"

# Merge and clean
MERGED_BAM="$WRKGDIR/${SAMPLE_ID}.bam"
if [ ${#LANES[@]} -eq 1 ]
then
	mv $BAM_FILE_LIST $MERGED_BAM
else # merge
	samtools merge $MERGED_BAM $BAM_FILE_LIST
fi
#clean
####rm $CLEANNING_STAGE_1
#for LANE in "${LANES[@]}"
#do
#        BAM_FILE1="$WRKGDIR/${SAMPLE_ID}_${LANE}.bam"
#        rm $BAM_FILE1
#done
#fi

# Sort
SORTED_FILE="$OUTDIR/${SAMPLE_ID}.sorted"
SORTED_BAM_FILE="$OUTDIR/${SAMPLE_ID}.sorted.bam"
SORTED_INDX_FILE="${SORTED_BAM_FILE}.bai"

echo "Sorting $MERGED_BAM to $SORTED_FILE"
samtools sort $MERGED_BAM $SORTED_FILE
samtools index $SORTED_BAM_FILE

#Clean out large files from scratch
####rm $MERGED_BAM

################### cleaning bit #########################################
####rm -r $WRKGDIR
echo '['`date`']:''Directory ' $WRKGDIR ' is removed from ' $HOSTNAME '.' >> ${RUNNING_INFO_FILE}
echo '['`date`']:''BWA alignment is done.' >> ${RUNNING_INFO_FILE}
echo "[" `date` "]: BWA alignment completed."

