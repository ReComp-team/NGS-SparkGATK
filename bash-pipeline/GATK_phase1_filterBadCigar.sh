#! /bin/bash
#$ -cwd
#$ -j y
#$ -l h="node1[7-9]"
#$ -pe smp 4

# #$ -l mem_free=40G
# #$ -l mem_free=16G

##### Can use without "-rf BadCigar", but sometime aligners do produce alignment with doggy CIGAR

source /etc/profile.d/modules.sh
module load apps/samtools/0.1.18/gcc-4.4.6
#module load apps/gatk/2.6.4/noarch
GATKDIR=/users/njc97/apps/GenomeAnalysisTK-2.7-2-g6bda569

cwd=`pwd`; export cwd

SAMPLE_ID=$1
SAMPLE_PATH=$2
REF_DIR=$3
SCRATCH_DIR=$4
RUNNING_INFO_FILE=$5

echo "[" `date` "]: $0 started."
#INDIR="${SAMPLE_PATH}/${SAMPLE_ID}"
#INDIR=$SAMPLE_PATH

INDIR=`dirname $RUNNING_INFO_FILE`
WRKGDIR="${SCRATCH_DIR}/${SAMPLE_ID}.GATKpipe.GATK_P1"
OUTDIR="${INDIR}"
REF_FILE="${REF_DIR}/ucsc.hg19.YAOBO.fasta"
DBSNP_VCF="${REF_DIR}/dbsnp_138.hg19.YAOBO.vcf"

echo '['`date`']:''Making working directory on ' $HOSTNAME '. ' >> $RUNNING_INFO_FILE
echo '['`date`']:''Working directory on ' $WRKGDIR '. ' >> $RUNNING_INFO_FILE
echo '' >> $RUNNING_INFO_FILE

mkdir $WRKGDIR

PICARD_OUTDIR="$OUTDIR/picard"
SORTED_BAM_FILE_NODUPS="$PICARD_OUTDIR/${SAMPLE_ID}_nodups.sorted.bam"
SORTED_INDX_FILE_NODUPS="${SORTED_BAM_FILE_NODUPS}.bai"

################## GATK Bit ##################################

echo '['`date`']:''Making GATK output folder.' >> ${RUNNING_INFO_FILE}
GATK_OUTDIR="${INDIR}/GATK"
mkdir -p $GATK_OUTDIR
METRICS="$WRKGDIR/${SAMPLE_ID}_nodups.sorted.bam.metrics.log"
INTERVALS="$WRKGDIR/${SAMPLE_ID}_nodups.sorted.bam.intervals"
REALIGNED_BAM="$WRKGDIR/${SAMPLE_ID}_nodups.sorted.realigned.bam"
RECAL_TABLE_GRP="$WRKGDIR/${SAMPLE_ID}_nodups.sorted.realigned.bam.grp"
RECALIBRATED_BAM="$GATK_OUTDIR/${SAMPLE_ID}_nodups.sorted.realigned.Recal.bam"
RECALIBRATED_REDUCED_READS_BAM="$GATK_OUTDIR/${SAMPLE_ID}_nodups.sorted.realigned.Recal.reducedReads.bam"
COVARIATES="-cov ReadGroupCovariate -cov QualityScoreCovariate -cov ContextCovariate -cov CycleCovariate" 

### GATK generate large file, ensure cleaning while running ###########################
echo '['`date`']:''GATK: Creating realignment intervals...' >> ${RUNNING_INFO_FILE}
java -jar $GATKDIR/GenomeAnalysisTK.jar -rf BadCigar -T RealignerTargetCreator -I $SORTED_BAM_FILE_NODUPS -R $REF_FILE -o $INTERVALS
echo '['`date`']:''GATK: Realigning reads...' >> ${RUNNING_INFO_FILE}
java -jar $GATKDIR/GenomeAnalysisTK.jar -rf BadCigar -T IndelRealigner -I $SORTED_BAM_FILE_NODUPS -R $REF_FILE -targetIntervals $INTERVALS -o $REALIGNED_BAM
rm $INTERVALS
echo '['`date`']:''GATK: Calculating recalibration tables...' >> ${RUNNING_INFO_FILE}
java -Xmx6g -jar $GATKDIR/GenomeAnalysisTK.jar -rf BadCigar -T BaseRecalibrator -nct 8 -I $REALIGNED_BAM -R $REF_FILE $COVARIATES -knownSites $DBSNP_VCF -o $RECAL_TABLE_GRP
echo '['`date`']:''GATK: Creating Recalibrated alignment file...' >> ${RUNNING_INFO_FILE}
java -Xmx6g -jar $GATKDIR/GenomeAnalysisTK.jar -rf BadCigar -T PrintReads -nct 8 -R $REF_FILE -I $REALIGNED_BAM -BQSR $RECAL_TABLE_GRP -o $RECALIBRATED_BAM
rm $REALIGNED_BAM
rm $RECAL_TABLE_GRP
echo '['`date`']:''GATK: Redeucing reads...' >> ${RUNNING_INFO_FILE}
java -Xmx8g -jar $GATKDIR/GenomeAnalysisTK.jar -T ReduceReads -R $REF_FILE --minimum_mapping_quality 20 -I $RECALIBRATED_BAM -o $RECALIBRATED_REDUCED_READS_BAM
echo '['`date`']:''GATK: Indexing bam files...' >> ${RUNNING_INFO_FILE}
samtools index $RECALIBRATED_BAM
samtools index $RECALIBRATED_REDUCED_READS_BAM
echo '['`date`']:''GATK: Phase 1 is done.' >> ${RUNNING_INFO_FILE}

################### cleaning bit #########################################
rm -r $WRKGDIR
echo '['`date`']:''Directory ' $WRKGDIR ' is removed from ' $HOSTNAME '.' >> ${RUNNING_INFO_FILE}
echo "[" `date` "]: GATK: Phase 1 has completed."

