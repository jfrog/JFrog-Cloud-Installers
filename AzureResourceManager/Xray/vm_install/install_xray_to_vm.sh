#!/bin/bash

# Upgrade version for every release
XRAY_VERSION=$1

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y

# Download Xray
cd /opt/
wget -O jfrog-xray-${XRAY_VERSION}-deb.tar.gz 'https://releases.jfrog.io/artifactory/jfrog-xray/xray-deb/'${XRAY_VERSION}'/jfrog-xray-'${XRAY_VERSION}'-deb.tar.gz' \
>> /var/log/download-xray.log 2>&1

tar -xvf jfrog-xray-${XRAY_VERSION}-deb.tar.gz
rm jfrog-xray-${XRAY_VERSION}-deb.tar.gz
cd jfrog-xray-${XRAY_VERSION}-deb

# Generate txt file with the parameters to use in the interactive installation script
cat <<EOF >/opt/jfrog-xray-${XRAY_VERSION}-deb/input.txt
/var/opt/jfrog/xray
http://
Y
EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
replace_with_host_ip
N
n
postgres://{postgres_server_name}.postgres.database.azure.com:5432/xray?sslmode=disable
xray@postgres_server_name
password
EOF

cat <<EOF >/opt/jfrog-xray-${XRAY_VERSION}-deb/bin/installer.yaml
installer:
  ha: n
  data_dir: /var/opt/jfrog/xray
  node:
    ip: 10.0.0.4
  install_postgresql: n
shared:
  jfrogUrl: http://testrt.cloudapp.azure.com
  security:
    joinKey: EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: postgres://{postgres_server_name}.postgres.database.azure.com:5432/xray?sslmode=disable
    username: xray@postgres_server_name
    password: password
  rabbitMq:
    password: JFXR_RABBITMQ_COOKIE
EOF

# Run interactive installation script with default parameters
cat "/opt/jfrog-xray-${XRAY_VERSION}-deb/input.txt" | ./install.sh >> /var/log/install-xray.log 2>&1

# Add VM image Callhome to the Xray instance
cat <<EOF >>/opt/jfrog/xray/app/bin/xray.default
export PARTNER_ID=Partner/ACC-007221
export INTEGRATION_NAME=ARM_xray-vm/1.0.0
EOF

# Remove Xray service from boot up run
sudo systemctl disable xray.service