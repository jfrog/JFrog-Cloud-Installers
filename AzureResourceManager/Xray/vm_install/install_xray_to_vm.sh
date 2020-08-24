#!/bin/bash

# Upgrade version for every release
XRAY_VERSION=3.6.2

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y

# Download Xray
cd /opt/
wget -O jfrog-xray-${XRAY_VERSION}-deb.tar.gz 'https://bintray.com/jfrog/jfrog-xray/download_file?agree=true&artifactPath=/jfrog/jfrog-xray/xray-deb/'${XRAY_VERSION}'/jfrog-xray-'${XRAY_VERSION}'-deb.tar.gz&callback_id=&product=org.grails.taglib.NamespacedTagDispatcher' \
>> /var/log/download-xray.log 2>&1
tar -xvf jfrog-xray-${XRAY_VERSION}-deb.tar.gz
rm jfrog-xray-${XRAY_VERSION}-deb.tar.gz
cd jfrog-xray-${XRAY_VERSION}-deb

# Generate txt file with the parameters to use in the interactive installation script
cat <<EOF >/opt/jfrog-xray-${XRAY_VERSION}-deb/input.txt
/var/opt/jfrog/xray
http://
EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
replace_with_host_ip
N
n
postgres://{postgres_server_name}.postgres.database.azure.com:5432/xray?sslmode=disable
xray@postgres_server_name
password
EOF

# Run interactive installation script with default parameters
cat "/opt/jfrog-xray-${XRAY_VERSION}-deb/input.txt" | ./install.sh >> /var/log/install-xray.log 2>&1

# Add Callhome to the Xray instance
cat <<EOF >>/opt/jfrog/xray/app/bin/xray.default
export PARTNER_ID=Partner/ACC-007221
export INTEGRATION_NAME=ARM_xray/1.0.0
EOF

# Remove Xray service from boot up run
sudo systemctl disable xray.service