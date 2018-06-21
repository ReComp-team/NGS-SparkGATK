#! /bin/bash
#$ -cwd
#$ -j y

source /etc/profile.d/modules.sh
module load apps/samtools/0.1.18/gcc-4.4.6
module load apps/bedtools/2.17.0/gcc-4.4.6

cwd=`pwd`; export cwd

SAMPLE_ID=$1
SAMPLE_PATH=$2
RUNNING_INFO_FILE=$3
TARGETS=$4
#INDIR="${SAMPLE_PATH}/${SAMPLE_ID}"
#INDIR=$SAMPLE_PATH
OUTDIR=`dirname $RUNNING_INFO_FILE`
GATK_OUTDIR="${OUTDIR}/GATK"
RECALIBRATED_BAM="$GATK_OUTDIR/${SAMPLE_ID}_nodups.sorted.realigned.Recal.bam"
RECALIBRATED_REDUCED_READS_BAM="$GATK_OUTDIR/${SAMPLE_ID}_nodups.sorted.realigned.Recal.reducedReads.bam"

################## Bedtools Bit ##################################
echo '['`date`']:''Making Bedtools output folder and calculating coverage...' >> ${RUNNING_INFO_FILE}
BEDTOOLS_OUTDIR="${OUTDIR}/bedtools"
mkdir -p $BEDTOOLS_OUTDIR
COVERAGE_OUTPUT="$BEDTOOLS_OUTDIR/${SAMPLE_ID}_coverage_on_targets.txt"
echo "coverageBed -abam $RECALIBRATED_BAM -b $TARGETS -hist > $COVERAGE_OUTPUT"
coverageBed -abam $RECALIBRATED_BAM -b $TARGETS -hist > $COVERAGE_OUTPUT
echo '['`date`']:''Done.' >> ${RUNNING_INFO_FILE}
echo '' >> ${RUNNING_INFO_FILE}

