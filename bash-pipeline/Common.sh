#SAMPLE_PATH="/users/njc97/data/Files_HG/Eldarina_Files"
SAMPLE_PATH="/users/njc97/data/njc97/PFC_028-034/"
OUTPUT_PATH="/users/njc97/data/njc97/7Samples-eval/"
#REF_DIR="/users/data/reference/hsapiens/hg19/GATK_bundle"
REF_DIR="/users/data/GATK/bundle2.8/hg19/"
REF_FILE="${REF_DIR}/ucsc.hg19.YAOBO.fasta"
SCRATCH_DIR="/users/njc97/scratch" #scatch folder path on each node

function check_exit_code {
  EC=$?
  if [ $EC -ne 0 ] ; then
    echo "Previous command failed"
    exit $EC
  fi
}

