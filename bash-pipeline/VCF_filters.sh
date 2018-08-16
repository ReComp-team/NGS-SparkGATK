#! /bin/bash
#$ -cwd
#$ -j y

##### This script is to select samples of interest from the large VCF file.

source /etc/profile.d/modules.sh

module load apps/gatk/2.5.2/noarch
module load apps/perl/5.16.1/gcc-4.4.6

source /users/njc97/scripts/Yaobo/Common.sh

SAMPLE_FILTERS=(PFC_0098_98_05_ACTGAT PFC_0169_AC_TAGCTT PFC_0172_RM_CCGTCC)

#INPUT_VCF="/users/a5907529/lustre/Kidney_20130211/UnifiedGenotyper_oldOnes_A1569_A1982_A1671b1/unifiedgenotyper_recali_SNP_INDEL.vcf"
INPUT_VCF="$OUTPUT_PATH/variants/unifiedgenotyper_recali_SNP_INDEL.vcf"

#TARGETS="/users/a5907529/lustre/Yaobo/GenomeData/TruSeq-Exome-Targeted-Regions.bed"
TARGETS="/users/data/Files_YX/npm65/TruSeq-Exome-Targeted-Regions.bed"

#REF_FILE="/users/a5907529/lustre/Yaobo/GenomeData/GATK_bundle/ucsc.hg19.4GATK.fasta"
REF_FILE="${REF_DIR}/ucsc.hg19.4GATK.fasta"

SKIP_FIRST=0

for filter in ${SAMPLE_FILTERS[@]}
do
  echo "Filtering of ${filter}* ..."
  SAMPLE_SELECTED_VCF="$OUTPUT_PATH/variants/${filter}.sample_selected.filtered.vcf"
  SAMPLE_SELECTED_OnTargets="$OUTPUT_PATH/variants/${filter}.sample_selected.filtered.onTargets.vcf"

  #select samples
  # exclude non-variant sites
  # exclude sites with no variant passed the filters
  if [ $SKIP_FIRST -eq 0 ] ; then
    java -Xmx4g -jar $GATKDIR/GenomeAnalysisTK.jar -T SelectVariants -R $REF_FILE \
      --variant $INPUT_VCF \
      -env -ef \
      -o $SAMPLE_SELECTED_VCF \
      -se ${filter}\*
      #-se 'PFC_0030_MSt_GAGTGG*'
    check_exit_code
  fi # SKIP_FIRST

  #select variants on targets
  java -Xmx4g -jar $GATKDIR/GenomeAnalysisTK.jar -T SelectVariants -R $REF_FILE \
    --variant $SAMPLE_SELECTED_VCF \
    -o $SAMPLE_SELECTED_OnTargets \
    -L $TARGETS \
    --interval_padding 500
  check_exit_code
done

