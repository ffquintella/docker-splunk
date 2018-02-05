mkdir -p /srv/application-data/splunk-test/data
mkdir -p /srv/application-data/splunk-test/var
mkdir -p /srv/application-config/splunk-test

docker run --rm --name=splunk -p '8080:8080' -p '8000:8000' -v /srv/application-data/splunk-test/data:/opt/splunk/data -v /srv/application-config/splunk-test:/opt/splunk/etc -v /srv/application-data/splunk-test/var:/opt/splunk/var ffquintella/splunk:latest
