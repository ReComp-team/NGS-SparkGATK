#! /bin/bash

## The script can launch exome pipeline for multipul samples.
## The pipeline containing fowllowing steps: 
## Alignment(BWA+samtools), Removal of duplicates (Picard), Local realignment and quality recalibration(GATK), Calculation of coverage (Bedtools)
## Each step is done with a seperated script. Paths of these scripts need to be adjusted to where they are on qsub lines.
## Samples must be whithin a same folder and each has its own folder containing fastq files.
## SAMPLE_PATH is the path to the folder contain all samples
################## Paras need to be adjusted for different samples #########################
SCRIPTSDIR=.
if [ -f "${SCRIPTSDIR}/Common.sh" ]; then
  source ${SCRIPTSDIR}/Common.sh
else
  echo "No Common script available."
  exit 1
fi

#INALL=(child1 child2 mother)
#INALL=(PFC_0030_MSt_GAGTGG PFC_0091_104_98_ATCACG PFC_0098_98_05_ACTGAT PFC_0169_AC_TAGCTT PFC_0172_RM_CCGTCC)
INALL=(PFC_0028_SW_CGTACG PFC_0029_IUH_AGTTCC PFC_0030_MSt_GAGTGG PFC_0031_DR_TTAGGC PFC_0032_IMc_CAGATC PFC_0033_MH_AGTTCC)
#INALL=(Probe.PFC_0030_MSt_GAGTGG)
NUM_SAMPLES=${#INALL[@]}
#SAMPLE_PATH="/users/npm65/data/MotherChild/"

#INALL=(JS15 JS16 JS17 JS18 JS19)
#SAMPLE_PATH="/users/a5907529/lustre/Kidney_20130211/A1671_Fastq/batch2"
###############################

############################### Paras may need to be adjusted ###############################
#TARGETS="/users/a5907529/lustre/Yaobo/GenomeData/TruSeq-Exome-Targeted-Regions.txt" #Genome regions of the exome capture kit, only used when bedtools produces coverage on these regions.
TARGETS="/users/data/njc97/Yaobo_pipeline/TruSeq-Exome-Targeted-Regions.txt"
#REF_DIR="/users/a5907529/lustre/Yaobo/GenomeData/GATK_bundle" # Reference genome folder. For human it's better to download it from GATK site directly.
#REF_DIR="/users/data/reference/hsapiens/hg19/GATK_bundle"
#SCRATCH_DIR="/users/npm65/scratch" #scatch folder path on each node
REALIGN_RECALIB_BAM_LIST_FILE="$OUTPUT_PATH/RealignedBamFile.list" # File that will contain all quality calibrated bam files from this workflow, will be the input for variant calling step  
REDUCED_BAM_LIST_FILE="$OUTPUT_PATH/ReducedBamFile.list" # List of reduced sized bam files from this workflow. It will be the input for UnifiedGenotypecaller
###############################

#Ensure the two files are empty.
rm -f $REALIGN_RECALIB_BAM_LIST_FILE
touch $REALIGN_RECALIB_BAM_LIST_FILE
rm -f $REDUCED_BAM_LIST_FILE
touch $REDUCED_BAM_LIST_FILE

## Submitting jobs ##
OUTPUT_VCF_PREFIX="${INALL[0]}_to_${INALL[${#INALL[@]}-1]}" 
JOB_ID_LIST="" #seperared with ','
REALIGN_RECALIB_BAM_LIST="" #seperared with ','
REALIGN_RECALIB_REDUCED_BAM_LIST=""  #seperared with ','

COUNT=0
while [ $COUNT -lt $NUM_SAMPLES ]
do
	SAMPLE_ID=${INALL[$COUNT]}
	#SAMPLE_DIR="$SAMPLE_PATH/$SAMPLE_ID"
        SAMPLE_DIR=$SAMPLE_PATH

	RUNNING_INFO_FILE="${SAMPLE_PATH}/${SAMPLE_ID}/running_status_GATK_pipe.txt" #To record time spend on each step
        mkdir -p "${SAMPLE_PATH}/${SAMPLE_ID}"
	touch $RUNNING_INFO_FILE

        #JOB_ID1="b2q_${SAMPLE_ID}"
        JOB_ID2="align_${SAMPLE_ID}"
        JOB_ID3="Pica_${SAMPLE_ID}"
        JOB_ID4="G1_${SAMPLE_ID}"
        JOB_ID5="Bed_${SAMPLE_ID}"
        #JOB_ID6="Vars_${SAMPLE_ID}"
        #JOB_ID7="CNV_${SAMPLE_ID}"

	if [ $COUNT -eq 0 ]
	then
		#JOB_ID_LIST="${JOB_ID1}"
		REALIGN_RECALIB_BAM_LIST="${SAMPLE_PATH}/${SAMPLE_ID}/GATK/${SAMPLE_ID}_nodups.sorted.realigned.Recal.bam"
		REALIGN_RECALIB_REDUCED_BAM_LIST="${SAMPLE_PATH}/${SAMPLE_ID}/GATK/${SAMPLE_ID}_nodups.sorted.realigned.Recal.reducedReads.bam"
	else
		#JOB_ID_LIST="${JOB_ID_LIST},${JOB_ID1}"
		REALIGN_RECALIB_BAM_LIST="${REALIGN_RECALIB_BAM_LIST},${SAMPLE_PATH}/${SAMPLE_ID}/GATK/${SAMPLE_ID}_nodups.sorted.realigned.Recal.bam"
		REALIGN_RECALIB_REDUCED_BAM_LIST="${REALIGN_RECALIB_REDUCED_BAM_LIST},${SAMPLE_PATH}/${SAMPLE_ID}/GATK/${SAMPLE_ID}_nodups.sorted.realigned.Recal.reducedReads.bam"
	fi
	echo "${SAMPLE_PATH}/${SAMPLE_ID}/GATK/${SAMPLE_ID}_nodups.sorted.realigned.Recal.bam" >> $REALIGN_RECALIB_BAM_LIST_FILE
	echo "${SAMPLE_PATH}/${SAMPLE_ID}/GATK/${SAMPLE_ID}_nodups.sorted.realigned.Recal.reducedReads.bam" >> $REDUCED_BAM_LIST_FILE

	READ_GROUP_ID=$(($COUNT+123))

	echo '['`date`']:''Submiting jobs...' >> ${RUNNING_INFO_FILE}
	#bam2fastq	
	#qsub -N $JOB_ID1 /users/a5907529/lustre/scripts/BWA_GATK_pipe/bam2fastq.sh $SAMPLE_ID $SAMPLE_PATH $BAM_FILE $RUNNING_INFO_FILE
	#bwa alignment
	qsub -N $JOB_ID2 ${SCRIPTSDIR}/BWA.sh $SAMPLE_ID $SAMPLE_PATH $REF_DIR $SCRATCH_DIR $RUNNING_INFO_FILE
	#picard to remove dups and add read group info	
	qsub -hold_jid $JOB_ID2 -N $JOB_ID3 ${SCRIPTSDIR}/picard.sh $SAMPLE_ID $SAMPLE_PATH $REF_DIR $SCRATCH_DIR $RUNNING_INFO_FILE $READ_GROUP_ID
	#qsub -N $JOB_ID3 ${SCRIPTSDIR}/picard.sh $SAMPLE_ID $SAMPLE_PATH $REF_DIR $SCRATCH_DIR $RUNNING_INFO_FILE $READ_GROUP_ID
	#GATK p1
	qsub -hold_jid $JOB_ID3 -N $JOB_ID4 ${SCRIPTSDIR}/GATK_phase1_filterBadCigar.sh $SAMPLE_ID $SAMPLE_PATH $REF_DIR $SCRATCH_DIR $RUNNING_INFO_FILE
	#qsub -R y -N $JOB_ID4 ${SCRIPTSDIR}/GATK_phase1_filterBadCigar.sh $SAMPLE_ID $SAMPLE_PATH $REF_DIR $SCRATCH_DIR $RUNNING_INFO_FILE
	#bedtools
	#qsub -hold_jid $JOB_ID4 -N $JOB_ID5 ${SCRIPTSDIR}/bedtools_coverage.sh $SAMPLE_ID $SAMPLE_PATH $RUNNING_INFO_FILE $TARGETS
	#qsub -N $JOB_ID5 ${SCRIPTSDIR}/bedtools_coverage.sh $SAMPLE_ID $SAMPLE_PATH $RUNNING_INFO_FILE $TARGETS
	#Varscan
	#qsub -hold_jid $JOB_ID4 -N $JOB_ID6 /users/a5907529/lustre/scripts/BWA_GATK_pipe/Varscan.sh
	#CNV Caller
	#qsub -hold_jid $JOB_ID4 -N $JOB_ID7 /users/a5907529/lustre/scripts/BWA_GATK_pipe/CNV_caller.sh

	echo '['`date`']:''All jobs have submitted.' >> ${RUNNING_INFO_FILE}
	echo '' >> ${RUNNING_INFO_FILE}
	COUNT=$(($COUNT+1))
done

echo $SAMPLE_PATH
echo $REF_DIR
echo $OUTPUT_VCF_PREFIX
echo $JOB_ID_LIST
echo $REALIGN_RECALIB_BAM_LIST
echo $REALIGN_RECALIB_REDUCED_BAM_LIST

####################### add more exome to increase accuracy of variants call ###############################
#V_CALL_SAMPLES_PATH="/users/data/GATK_V_call_Added_Samples/AROS_bams"
#V_CALL_SAMPLES_NAMES=(Sample_PFC_0138_AP Sample_PFC_0144_MS Sample_PFC_0147_ND Sample_PFC_0151_HB Sample_PFC_0152_GB Sample_PFC_0156_PD Sample_PFC_0158_GS Sample_PFC_0167_GR Sample_PFC_0168_MH Sample_PFC_0169_AC Sample_PFC_0170_BA Sample_PFC_0173_TB Sample_PFC_0174_AB Sample_PFC_0176_MS)
#V_CALL_SAMPLES_NUMBER=14  ####### This can control how many samples are added to the calling pipe
#V_CALL_REALIGN_RECALIB_BAM_LIST=""
#V_CALL_REALIGN_RECALIB_REDUCED_BAM_LIST=""

#COUNT=0
#while [ $COUNT -lt $V_CALL_SAMPLES_NUMBER ]
#do
#	V_CALL_SAMPLE_ID=${V_CALL_SAMPLES_NAMES[$COUNT]}
#	if [ $COUNT -eq 0 ]
#	then
#		V_CALL_REALIGN_RECALIB_BAM_LIST="${V_CALL_SAMPLES_PATH}/GATK/${V_CALL_SAMPLE_ID}_nodups.sorted.realigned.Recal.bam"
#		V_CALL_REALIGN_RECALIB_REDUCED_BAM_LIST="${V_CALL_SAMPLES_PATH}/GATK/${V_CALL_SAMPLE_ID}_nodups.sorted.realigned.Recal.reducedReads.bam"
#	else
#		V_CALL_REALIGN_RECALIB_BAM_LIST="${V_CALL_REALIGN_RECALIB_BAM_LIST},${V_CALL_SAMPLES_PATH}/GATK/${V_CALL_SAMPLE_ID}_nodups.sorted.realigned.Recal.bam"
#		V_CALL_REALIGN_RECALIB_REDUCED_BAM_LIST="${V_CALL_REALIGN_RECALIB_REDUCED_BAM_LIST},${V_CALL_SAMPLES_PATH}/GATK/${V_CALL_SAMPLE_ID}_nodups.sorted.realigned.Recal.reducedReads.bam"
#	fi
	
	#echo "${V_CALL_SAMPLES_PATH}/GATK/${V_CALL_SAMPLE_ID}_nodups.sorted.realigned.Recal.reducedReads.bam" >> $REDUCED_BAM_LIST_FILE
#	COUNT=$(($COUNT+1))
#done
####################### 

