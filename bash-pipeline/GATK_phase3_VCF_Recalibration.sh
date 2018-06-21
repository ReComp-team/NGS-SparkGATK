#! /bin/bash
#$ -cwd
#$ -j y
#$ -l h="node1[7-9]"
#$ -pe smp 4

# #$ -l mem_free=40G


# Load Modules
source /etc/profile.d/modules.sh

module load apps/R/3.0.0/gcc-4.4.6+lapack-3.4.1+blas-1
#module load apps/gatk/2.5.2/noarch
module load apps/gatk/2.8.1/noarch

cwd=`pwd`; export cwd

echo "[" `date` "]: $0 started"

source /users/njc97/scripts/Yaobo/Common.sh

SAMPLE_PATH="$OUTPUT_PATH/variants"
#REF_DIR="/users/data/reference/hsapiens/hg19/GATK_bundle"
#OUTPUT_VCF_PREFIX="unifiedgenotyper"
OUTPUT_VCF_PREFIX="HaplotypeCaller"
#RAW_VCF_INPUT="$SAMPLE_PATH/${OUTPUT_VCF_PREFIX}.combined.vcf"
RAW_VCF_INPUT="$SAMPLE_PATH/HaplotypeCaller_All.vcf"

#REF_FILE="${REF_DIR}/ucsc.hg19.4GATK.fasta"
HAPMAP="${REF_DIR}/hapmap_3.3.hg19.YAOBO.vcf"
DBSNP_137="${REF_DIR}/dbsnp_138.hg19.YAOBO.vcf"
OMNI="${REF_DIR}/1000G_omni2.5.hg19.YAOBO.vcf"
MILLS_INDEL="${REF_DIR}/Mills_and_1000G_gold_standard.indels.hg19.YAOBO.vcf"

SNP_RECAL_FILE="${RAW_VCF_INPUT}.SNP.recali"
SNP_TRANCH_FILE="${RAW_VCF_INPUT}.SNP.tranches"
SNP_RECAL_R_SCRIPT="${RAW_VCF_INPUT}.SNP.rscript"
SNP_RECALI_OUTPUT="$SAMPLE_PATH/${OUTPUT_VCF_PREFIX}_recali_SNP.vcf"

INDEL_RECAL_FILE="${RAW_VCF_INPUT}.INDEL.recali"
INDEL_TRANCH_FILE="${RAW_VCF_INPUT}.INDEL.tranches"
INDEL_RECAL_R_SCRIPT="${RAW_VCF_INPUT}.INDEL.rscript"
INDEL_RECALI_OUTPUT="$SAMPLE_PATH/${OUTPUT_VCF_PREFIX}_recali_SNP_INDEL.vcf"

# SNP error model
java -Xmx4g -jar $GATKDIR/GenomeAnalysisTK.jar -T VariantRecalibrator -R $REF_FILE \
--maxGaussians 6 \
-resource:hapmap,known=false,training=true,truth=true,prior=15.0 $HAPMAP \
-resource:dbsnp,known=true,training=false,truth=false,prior=6.0 $DBSNP_137 \
-resource:omni,known=false,training=true,truth=false,prior=12.0 $OMNI \
-an QD \
-an HaplotypeScore \
-an MQRankSum \
-an ReadPosRankSum \
-an FS \
-an MQ \
#-an InbreedingCoeff \
-mode SNP \
-input ${RAW_VCF_INPUT} \
-recalFile $SNP_RECAL_FILE \
-tranchesFile $SNP_TRANCH_FILE \
-rscriptFile $SNP_RECAL_R_SCRIPT
check_exit_code

java -Xmx4g -jar $GATKDIR/GenomeAnalysisTK.jar -T ApplyRecalibration -R $REF_FILE \
-input ${RAW_VCF_INPUT} \
--ts_filter_level 99.0 \
-recalFile $SNP_RECAL_FILE \
-tranchesFile $SNP_TRANCH_FILE \
-mode SNP \
-o $SNP_RECALI_OUTPUT
check_exit_code

#indel model
java -Xmx4g -jar $GATKDIR/GenomeAnalysisTK.jar -T VariantRecalibrator -R $REF_FILE \
--maxGaussians 4 \
-std 10.0 \
--percentBadVariants 0.12 \
-resource:mills,known=true,training=true,truth=true,prior=12.0 $MILLS_INDEL \
-an QD \
-an ReadPosRankSum \
-an FS \
#-an InbreedingCoeff \
-mode INDEL \
-input $RAW_VCF_INPUT \
-recalFile $INDEL_RECAL_FILE \
-tranchesFile $INDEL_TRANCH_FILE \
-rscriptFile $INDEL_RECAL_R_SCRIPT
check_exit_code

java -Xmx4g -jar $GATKDIR/GenomeAnalysisTK.jar -T ApplyRecalibration -R $REF_FILE \
-input $SNP_RECALI_OUTPUT \
--ts_filter_level 95.0 \
-recalFile $INDEL_RECAL_FILE \
-tranchesFile $INDEL_TRANCH_FILE \
-mode INDEL \
-o $INDEL_RECALI_OUTPUT
check_exit_code

echo "[" `date` "]: $0 has completed."
