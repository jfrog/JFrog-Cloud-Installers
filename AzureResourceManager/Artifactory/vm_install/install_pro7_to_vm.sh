#!/bin/bash

# Upgrade version for every release
ARTIFACTORY_VERSION=$1

UBUNTU_CODENAME=$(cat /etc/lsb-release | grep "^DISTRIB_CODENAME=" | sed "s/DISTRIB_CODENAME=//")

export DEBIAN_FRONTEND=noninteractive

# install the wget and curl
apt-get update
apt-get -y install wget curl>> /tmp/install-curl.log 2>&1

#Generate Self-Signed Cert
mkdir -p /etc/pki/tls/private/ /etc/pki/tls/certs/
openssl req -nodes -x509 -newkey rsa:4096 -keyout /etc/pki/tls/private/example.key -out /etc/pki/tls/certs/example.pem -days 356 -subj "/C=US/ST=California/L=SantaClara/O=IT/CN=*.localhost"

# install the Artifactory PRO and Nginx
echo "deb https://releases.jfrog.io/artifactory/artifactory-pro-debs ${UBUNTU_CODENAME} main" |  tee -a /etc/apt/sources.list
curl --retry 5 https://releases.jfrog.io/artifactory/api/gpg/key/public |  apt-key add -
apt-get update
apt-get -y install nginx>> /tmp/install-nginx.log 2>&1
apt-get -y install jfrog-artifactory-pro=${ARTIFACTORY_VERSION} >> /tmp/install-artifactory.log 2>&1

# Add callhome metadata (allow us to collect information)
mkdir -p /var/opt/jfrog/artifactory/etc/info
cat <<EOF >/var/opt/jfrog/artifactory/etc/info/installer-info.json
{
  "productId": "ARM_artifactory-pro-vm/1.0.0",
  "features": [
    {
      "featureId": "Partner/ACC-007221"
    }
  ]
}
EOF

#Install database drivers (for Java 11, path is different for RT6 and RT7)
curl --retry 5 -L -o /opt/jfrog/artifactory/app/artifactory/tomcat/lib/mysql-connector-java-5.1.38.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar >> /tmp/install-databse-driver.log 2>&1
curl --retry 5 -L -o /opt/jfrog/artifactory/app/artifactory/tomcat/lib/mssql-jdbc-7.4.1.jre11.jar https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/7.4.1.jre11/mssql-jdbc-7.4.1.jre11.jar >> /tmp/install-databse-driver.log 2>&1
curl --retry 5 -L -o /opt/jfrog/artifactory/app/artifactory/tomcat/lib/postgresql-42.2.18.jar https://jdbc.postgresql.org/download/postgresql-42.2.18.jar >> /tmp/install-databse-driver.log 2>&1

#Configuring nginx
rm /etc/nginx/sites-enabled/default

printf "\nartifactory.ping.allowUnauthenticated=true" >> /var/opt/jfrog/artifactory/etc/artifactory/artifactory.system.properties

chown artifactory:artifactory -R /var/opt/jfrog/artifactory/* && chown artifactory:artifactory -R /var/opt/jfrog/artifactory/etc/*

# Remove Artifactory service from boot up run
systemctl disable artifactory
systemctl disable nginx
