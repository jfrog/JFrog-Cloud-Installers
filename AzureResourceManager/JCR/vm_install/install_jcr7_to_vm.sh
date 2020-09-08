#!/bin/bash

# Upgrade version for every release
ARTIFACTORY_VERSION=7.7.3
UBUNTU_CODENAME=$(cat /etc/lsb-release | grep "^DISTRIB_CODENAME=" | sed "s/DISTRIB_CODENAME=//")

export DEBIAN_FRONTEND=noninteractive

# install the wget and curl
apt-get update
apt-get -y install wget curl>> /tmp/install-curl.log 2>&1

#Generate Self-Signed Cert
mkdir -p /etc/pki/tls/private/ /etc/pki/tls/certs/
openssl req -nodes -x509 -newkey rsa:4096 -keyout /etc/pki/tls/private/example.key -out /etc/pki/tls/certs/example.pem -days 356 -subj "/C=US/ST=California/L=SantaClara/O=IT/CN=*.localhost"

# install the Artifactory JCR and Nginx
echo "deb https://jfrog.bintray.com/artifactory-debs ${UBUNTU_CODENAME} main" | tee -a /etc/apt/sources.list
curl --retry 5 https://bintray.com/user/downloadSubjectPublicKey?username=jfrog | apt-key add -
apt-get update
apt-get -y install nginx>> /tmp/install-nginx.log 2>&1
apt-get -y install jfrog-artifactory-jcr=${ARTIFACTORY_VERSION} >> /tmp/install-artifactory.log 2>&1

# Add callhome metadata (allow us to collect information)
mkdir -p /var/opt/jfrog/artifactory/etc/info
cat <<EOF >/var/opt/jfrog/artifactory/etc/info/installer-info.json
{
  "productId": "ARM_artifactory-jcr/1.0.0",
  "features": [
    {
      "featureId": "Partner/ACC-007221"
    }
  ]
}
EOF

#Install database drivers (for Java 11, path is different for RT6 and RT7)
curl --retry 5 -L -o /opt/jfrog/artifactory/app/artifactory/tomcat/lib/mysql-connector-java-5.1.38.jar https://bintray.com/artifact/download/bintray/jcenter/mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar >> /tmp/install-databse-driver.log 2>&1
curl --retry 5 -L -o /opt/jfrog/artifactory/app/artifactory/tomcat/lib/mssql-jdbc-7.4.1.jre11.jar https://bintray.com/artifact/download/bintray/jcenter/com/microsoft/sqlserver/mssql-jdbc/7.4.1.jre11/mssql-jdbc-7.4.1.jre11.jar >> /tmp/install-databse-driver.log 2>&1
curl --retry 5 -L -o /opt/jfrog/artifactory/app/artifactory/tomcat/lib/postgresql-9.4.1212.jar https://jdbc.postgresql.org/download/postgresql-9.4.1212.jar >> /tmp/install-databse-driver.log 2>&1

#Configuring nginx
rm /etc/nginx/sites-enabled/default

printf "\nartifactory.ping.allowUnauthenticated=true" >> /var/opt/jfrog/artifactory/etc/artifactory/artifactory.system.properties

chown artifactory:artifactory -R /var/opt/jfrog/artifactory/* && chown artifactory:artifactory -R /var/opt/jfrog/artifactory/etc/*

# Remove Artifactory service from boot up run
systemctl disable artifactory
systemctl disable nginx