#!/bin/bash
DB_NAME=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_NAME=" | sed "s/DB_NAME=//")
DB_USER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_USER=" | sed "s/DB_ADMIN_USER=//")
DB_PASSWORD=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_PASSWD=" | sed "s/DB_ADMIN_PASSWD=//")
DB_SERVER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_SERVER=" | sed "s/DB_SERVER=//")
MASTER_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^MASTER_KEY=" | sed "s/MASTER_KEY=//")
JOIN_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^JOIN_KEY=" | sed "s/JOIN_KEY=//")
ARTIFACTORY_URL=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_URL=" | sed "s/ARTIFACTORY_URL=//")

export DEBIAN_FRONTEND=noninteractive

# Create master.key on each node
sudo mkdir -p /opt/jfrog/xray/var/etc/security/
cat <<EOF >/opt/jfrog/xray/var/etc/security/master.key
${MASTER_KEY}
EOF

# Xray should have the same join key as the Artifactory instance
# Both application should be deployed in the same Virtual Networks
HOSTNAME=$(hostname -i)
sed -i -e "s/ip:..*/ip: ${HOSTNAME}/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s#jfrogUrl:..*#jfrogUrl: \"${ARTIFACTORY_URL}\"#" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/joinKey:..*/joinKey: ${JOIN_KEY}/" /var/opt/jfrog/xray/etc/system.yaml
# DB configuration
sed -i -e "s/url: postgres:..*/url: \"postgres:\/\/${DB_SERVER}.postgres.database.azure.com:5432\/${DB_NAME}?sslmode=disable\"/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/username:..*/username: \"${DB_USER}\"/" /var/opt/jfrog/xray/etc/system.yaml
sed -i -e "s/password:..*/password: \"${DB_PASSWORD}\"/" /var/opt/jfrog/xray/etc/system.yaml

chown xray:xray -R /opt/jfrog/xray/var/etc/security/* && chown xray:xray -R /opt/jfrog/xray/var/etc/security/


# Enable and start Xray service
sudo systemctl enable xray.service
sudo systemctl start xray.service
sudo systemctl restart xray.service
