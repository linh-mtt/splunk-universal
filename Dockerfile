ARG SPLUNK_VERSION=10.2.3

FROM splunk/splunk:$SPLUNK_VERSION

USER root

RUN microdnf install -y net-snmp-libs net-snmp net-snmp-agent-libs compat-openssl10

RUN ln -s /usr/lib64/libnetsnmpmibs.so.35 /usr/lib64/libnetsnmpmibs.so.31
RUN ln -s /usr/lib64/libnetsnmpagent.so.35 /usr/lib64/libnetsnmpagent.so.31
RUN ln -s /usr/lib64/libnetsnmp.so.35 /usr/lib64/libnetsnmp.so.31

COPY mongo-passthrough.sh /opt/splunk/bin/

RUN set -ex \
    && cd /opt/splunk/bin \
    && files=$(ls mongod-* 2>/dev/null | grep -vE '^mongod-4\.' || true) \
    && for f in $files; do rm -f "$f"; done \
    && for f in $files; do ln -s /opt/splunk/bin/mongo-passthrough.sh "$f"; done \
    && for f in $files; do chmod +x "$f"; done

USER ansible
