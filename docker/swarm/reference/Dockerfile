FROM alpine:3.5

MAINTAINER Jhonattan Loza <toro.ryan.jcl@gmail.com>

RUN mkdir -p /reference_image
COPY ucsc.hg19.fasta.img /reference_image
COPY Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.img /reference_image

VOLUME /reference_image