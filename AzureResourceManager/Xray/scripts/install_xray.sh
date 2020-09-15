#!/bin/bash
DB_NAME=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_NAME=" | sed "s/DB_NAME=//")
DB_USER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_USER=" | sed "s/DB_ADMIN_USER=//")
DB_PASSWORD=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_PASSWD=" | sed "s/DB_ADMIN_PASSWD=//")
DB_SERVER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_SERVER=" | sed "s/DB_SERVER=//")
MASTER_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^MASTER_KEY=" | sed "s/MASTER_KEY=//")
JOIN_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^JOIN_KEY=" | sed "s/JOIN_KEY=//")
ARTIFACTORY_URL=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_URL=" | sed "s/ARTIFACTORY_URL=//")

export DEBIAN_FRONTEND=noninteractive

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
sudo add-apt-repository ppa:rmescandon/yq -y
sudo apt update -y
sudo apt install yq -y

# Create master.key on each node
sudo mkdir -p /opt/jfrog/xray/var/etc/security/
cat <<EOF >/opt/jfrog/xray/var/etc/security/master.key
${MASTER_KEY}
EOF

# Xray should have the same join key as the Artifactory instance
# Both application should be deployed in the same Virtual Networks
HOSTNAME=$(hostname -i)
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.database.url postgres://${DB_SERVER}.postgres.database.azure.com:5432/${DB_NAME}?sslmode=disable
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.database.username ${DB_USER}
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.database.password ${DB_PASSWORD}
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.rabbitMq.password JFXR_RABBITMQ_COOKIE
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.jfrogUrl ${ARTIFACTORY_URL}
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.security.joinKey ${JOIN_KEY}
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.node.ip ${HOSTNAME}

chown xray:xray -R /opt/jfrog/xray/var/etc/security/* && chown xray:xray -R /opt/jfrog/xray/var/etc/security/


# Enable and start Xray service
sudo systemctl enable xray.service
sudo systemctl start xray.service
sudo systemctl restart xray.service
