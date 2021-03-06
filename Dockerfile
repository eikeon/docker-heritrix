
#FROM openjdk:8u131-jdk
FROM openjdk:8-slim

MAINTAINER Andrew Jackson "anj@anjackson.net"

# update packages and install maven
#RUN echo "nameserver 8.8.8.8" | tee /etc/resolv.conf > /dev/null
RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y vim wget curl git maven

RUN \
  wget -q http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz && \
  gunzip GeoLite2-City.mmdb.gz && \
  curl -L -O https://download.elastic.co/beats/filebeat/filebeat_1.0.0-rc1_amd64.deb && \
  dpkg -i filebeat_1.0.0-rc1_amd64.deb

# Get the H3 LBS binary:
RUN curl -L -O https://sbforge.org/nexus/service/local/repositories/thirdparty/content/org/archive/heritrix/heritrix/3.3.0-LBS-2016-02/heritrix-3.3.0-LBS-2016-02-dist.zip && \
    unzip heritrix-3.3.0-LBS-2016-02-dist.zip && \
    ln -s /heritrix-3.3.0-LBS-2016-02 /h3-bin

# Add in the UKWA modules
RUN git clone https://github.com/ukwa/bl-heritrix-modules.git bl-heritrix-modules && \
    cd /bl-heritrix-modules && \
    git checkout 1.0.3 && \
    mvn install -DskipTests && \
    cp /bl-heritrix-modules/target/bl-heritrix-modules-*jar-with-dependencies.jar /h3-bin/lib

# Send in needed files:
COPY filebeat.yml /etc/filebeat/filebeat.yml
COPY start.sh /start.sh
COPY logging.properties /h3-bin/conf/logging.properties

# Finish setup:
EXPOSE 8443

ENV FOREGROUND true

#ENV MONITRIX_ENABLED true
#ENV HERITRIX_USER heritrix
#ENV HERITRIX_PASSWORD heritrix

#ENV JAVA_OPTS -Xmx2g -Dhttps.protocols=TLSv1,TLSv1.1,TLSv1.2
ENV JAVA_OPTS -Xmx2g

VOLUME /jobs

VOLUME /output

CMD /start.sh

