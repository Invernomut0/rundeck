# Dockerfile for rundeck

FROM debian:stretch

ENV SERVER_URL=https://localhost:4443 \
    RUNDECK_STORAGE_PROVIDER=file \
    RUNDECK_PROJECT_STORAGE_TYPE=file \
    NO_LOCAL_MYSQL=false \
    LOGIN_MODULE=RDpropertyfilelogin \
    JAAS_CONF_FILE=jaas-loginmodule.conf \
    KEYSTORE_PASS=adminadmin \
    TRUSTSTORE_PASS=adminadmin \
    CLUSTER_MODE=false

RUN export DEBIAN_FRONTEND=noninteractive && \
    echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list && \
    apt-get -qq update && \
    apt-get -qqy install -t stretch-backports --no-install-recommends apt-transport-https wget curl golang-go ca-certificates && \
    curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version=10.5 && \
    apt-get -qqy install -t stretch-backports --no-install-recommends bash openjdk-8-jre-headless ca-certificates-java supervisor procps sudo openssh-client mariadb-server mariadb-client postgresql-9.6 postgresql-client-9.6 pwgen git uuid-runtime parallel jq && \
    cd /tmp/ && \
    curl -Lo /tmp/rundeck.deb https://packagecloud.io/pagerduty/rundeck/packages/any/any/rundeck_3.4.5.20211018-1_all.deb/download.deb && \
    echo '58af119eedc5457757cb473532b8ecefed3d8b1bafa6fc4156ec6eaef177a406  rundeck.deb' > /tmp/rundeck.sig && \
    shasum -a256 -c /tmp/rundeck.sig && \
    curl -Lo /tmp/rundeck-cli.deb https://packagecloud.io/pagerduty/rundeck/packages/any/any/rundeck-cli_1.3.10-1_all.deb/download.deb && \
    echo 'e9f6fb2cd051b32b452a055ce5aa7e354b21e011a9c00c76e3d624c2338a3736  rundeck-cli.deb' > /tmp/rundeck-cli.sig && \
    shasum -a256 -c /tmp/rundeck-cli.sig && \
    cd - && \
    dpkg -i /tmp/rundeck*.deb && rm /tmp/rundeck*.deb && \
    mkdir -p /tmp/rundeck && \
    chown rundeck:rundeck /tmp/rundeck && \
    mkdir -p /var/lib/rundeck/.ssh && \
    chown rundeck:rundeck /var/lib/rundeck/.ssh && \
    sed -i "s/export RDECK_JVM=\"/export RDECK_JVM=\"\${RDECK_JVM} /" /etc/rundeck/profile && \
    curl -Lo /var/lib/rundeck/libext/rundeck-slack-incoming-webhook-plugin-0.11.jar https://github.com/higanworks/rundeck-slack-incoming-webhook-plugin/releases/download/v0.11.dev/rundeck-slack-incoming-webhook-plugin-0.11.jar && \
    echo 'efce8fa7891371bb8540b55d7eef645741566d411b3dbed43e9b7fe2e4d099a0  rundeck-slack-incoming-webhook-plugin-0.11.jar' > /tmp/rundeck-slack-plugin.sig && \
    cd /var/lib/rundeck/libext/ && \
    shasum -a256 -c /tmp/rundeck-slack-plugin.sig && \
    cd - && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
USER rundeck
RUN echo "Setup Akamai CLI" &&\
    cd /var/lib/rundeck &&\
    wget https://github.com/akamai/cli/releases/download/1.3.0/akamai-1.3.0-linuxamd64 &&\
    mv akamai-1.3.0-linuxamd64 akamai &&\
    chmod 755 akamai &&\
    printf "yes\nyes\nyes\n" | ./akamai &&\
    echo "[ccu]\nclient_secret = kgsKKUojS38pVoWe7B+ryW+zSwlWsSfBbCPTBCFvoyo=\nhost = akab-bzepu52nott6dfns-4ab2bv7wlb6pbipr.luna.akamaiapis.net\naccess_token = akab-uu2avmhogtcmusse-b6vp5po4wzku42gk\nclient_token = akab-wkbxs7h2bpeciux2-qmgzkzoelczsoojl" > .edgerc &&\
    printf "yes\nyes\n" | ./akamai install --force purge 
USER root
ADD content/ /
RUN chmod u+x /opt/run && \
    mkdir -p /var/log/supervisor && mkdir -p /opt/supervisor && \
    chmod u+x /opt/supervisor/rundeck && chmod u+x /opt/supervisor/mysql_supervisor && chmod u+x /opt/supervisor/fatalservicelistener

EXPOSE 4440 4443

VOLUME  ["/etc/rundeck", "/var/rundeck", "/var/lib/mysql", "/var/log/rundeck", "/opt/rundeck-plugins", "/var/lib/rundeck/logs", "/var/lib/rundeck/var/storage"]

ENTRYPOINT ["/opt/run"]
