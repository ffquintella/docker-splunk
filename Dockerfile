FROM ffquintella/docker-puppet:latest

MAINTAINER Felipe Quintella <docker-puppet@felipe.quintella.email>

LABEL version="6.3.2"
LABEL description="This image contais the splunk application to be used \
as a server."

ENV SPLUNK_PRODUCT splunk enterprise
ENV SPLUNK_VERSION 6.3.2
ENV SPLUNK_BUILD aaff59bb082c
#ENV SPLUNK_FILENAME splunklight-${SPLUNK_VERSION}-${SPLUNK_BUILD}-Linux-x86_64.tgz

ENV SPLUNK_HOME /opt/splunk
ENV SPLUNK_GROUP splunk
ENV SPLUNK_USER splunk
ENV SPLUNK_BACKUP_DEFAULT_ETC /var/opt/splunk


# Puppet stuff all the instalation is donne by puppet
# Just after it we clean up everthing so the end image isn't too big
RUN mkdir /etc/puppet; mkdir /etc/puppet/manifests
COPY manifests/base.pp /etc/puppet/manifests/
RUN /opt/puppetlabs/puppet/bin/puppet apply -l /tmp/puppet.log /etc/puppet/manifests/base.pp ;\
 yum clean all ; rm -rf /tmp/* ; rm -rf /var/cache/* ; rm -rf /var/tmp/*

# Ports Splunk Web, Splunk Daemon, KVStore, Splunk Indexing Port, Network Input, HTTP Event Collector
EXPOSE 8000/tcp 8089/tcp 8191/tcp 9997/tcp 1514 8088/tcp

WORKDIR /opt/splunk

# Configurations folder, var folder for everyting (indexes, logs, kvstore)
VOLUME [ "/opt/splunk/etc", "/opt/splunk/var" ]

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

# Ports Splunk Web, Splunk Daemon, KVStore, Splunk Indexing Port, Network Input, HTTP Event Collector
EXPOSE 8000/tcp 8089/tcp 8191/tcp 9997/tcp 1514 8088/tcp

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["start-service"]