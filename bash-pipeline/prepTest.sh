#!/bin/bash

SCRIPTSDIR=.

if [ -f "${SCRIPTSDIR}/Common.sh" ]; then
  source ${SCRIPTSDIR}/Common.sh
else
  echo "No Common script available."
  exit 1
fi

# Remove intermediate files and directories
shopt -s extglob
pushd ${SAMPLE_PATH}
rm -rf !(*.fastq.gz)
popd

# Remove the GATK queue data 
rm -rf .queue ${OUTPUT_PATH}/*

