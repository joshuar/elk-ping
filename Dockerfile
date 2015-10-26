FROM fedora:latest

MAINTAINER Joshua Rich "joshua.rich@gmail.com"

# Environment variables that set the versions and download URLs
ENV ES_VERSION 1.7.3
ENV ES_URL https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-$ES_VERSION.tar.gz
ENV LS_VERSION 1.5.4
ENV LS_URL https://download.elastic.co/logstash/logstash/logstash-$LS_VERSION.tar.gz
ENV KIBANA_VERSION 4.1.2

# Install required packages for build/run
RUN dnf -q -y --nogpgcheck install tar jre fping echoping supervisor && \
    dnf -q clean all

# Install Elasticsearch
RUN curl -s -L -o - $ES_URL | tar -xz -C /opt \
    && ln -s /opt/elasticsearch-$ES_VERSION /opt/elasticsearch \
    && mkdir /opt/elasticsearch/{data,logs,plugins}
RUN useradd -U -d /opt/elasticsearch -M -s /usr/bin/bash elasticsearch
RUN chown -R elasticsearch:elasticsearch /opt/elasticsearch-$ES_VERSION

# Install Logstash
RUN curl -s -L -o - $LS_URL | tar -xz -C /opt \
    && ln -s /opt/logstash-$LS_VERSION /opt/logstash
RUN mkdir -p /etc/logstash/conf.d
RUN mkdir -p /var/log/logstash
RUN useradd -U -d /opt/logstash -M -s /usr/bin/bash logstash
RUN chown -R logstash:logstash /opt/logstash-$LS_VERSION /etc/logstash /var/log/logstash

# Install Kibana
RUN mkdir -p /opt/kibana
RUN curl -s https://download.elasticsearch.org/kibana/kibana/kibana-$KIBANA_VERSION-linux-x64.tar.gz \
    | tar -C /opt/kibana --strip-components=1 -xzf -
RUN useradd -U -d /opt/kibana -M -s /usr/bin/bash kibana
RUN chown -R kibana:kibana /opt/kibana

# Remove build packages
RUN dnf -q -y erase tar

# Default volumes for Elasticsearch and Logstash
VOLUME ["/opt/elasticsearch/data","/opt/elasticsearch/config","/opt/elasticsearch/logs","/opt/elasticsearch/plugins","/etc/logstash","/var/log/logstash"]

# Expose ports
EXPOSE "5601/tcp" "9200/tcp" "9300/tcp"

# Supervisord config file for starting all services
COPY supervisord.conf /etc/supervisord.conf

# Run Supervisord
CMD ["/usr/bin/supervisord"]
