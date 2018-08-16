FROM atahualpa/spark-master:spark2.3.1-hadoop2.8.4

MAINTAINER Jhonattan Loza <toro.ryan.jcl@gmail.com>

COPY picard.jar /
COPY GenomeAnalysisTK_v3.8-0-ge9d806836.jar /
COPY hadoop-azure-2.7.3.jar /spark/jars/
COPY azure-storage-2.0.0.jar /spark/jars/

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
RUN apt-get install -y git-lfs
RUN git lfs install
RUN apt-get install unzip
RUN apt-get install wget
RUN apt-get install git

RUN mkdir /gatk
RUN apt-get update && apt-get install -y python git mlocate htop && export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8 && \
    wget https://github.com/broadinstitute/gatk/releases/download/4.0.2.0/gatk-4.0.2.0.zip && unzip gatk-4.0.2.0.zip -d gatk && \
    wget https://github.com/broadinstitute/gatk/releases/download/4.0.4.0/gatk-4.0.4.0.zip && unzip gatk-4.0.4.0.zip -d gatk && \
    wget https://github.com/broadinstitute/gatk/releases/download/4.0.5.0/gatk-4.0.5.0.zip && unzip gatk-4.0.5.0.zip -d gatk && \
    wget https://github.com/broadinstitute/gatk/releases/download/4.0.5.2/gatk-4.0.5.2.zip && unzip gatk-4.0.5.2.zip -d gatk && \
    cp /spark/conf/spark-defaults.conf.template /spark/conf/spark-defaults.conf && \
    echo "spark.eventLog.enabled             true" >> /spark/conf/spark-defaults.conf && \
    echo "spark.eventLog.dir                 file:///spark/logs/" >> /spark/conf/spark-defaults.conf

RUN rm /gatk-4.0.*.zip

ENV PATH="$PATH:/spark/bin"