#!/bin/bash
DB_NAME=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_NAME=" | sed "s/DB_NAME=//")
DB_USER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_USER=" | sed "s/DB_ADMIN_USER=//")
ACTUAL_DB_USER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ACTUAL_DB_ADMIN_USER=" | sed "s/ACTUAL_DB_ADMIN_USER=//")
DB_PASSWORD=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_PASSWD=" | sed "s/DB_ADMIN_PASSWD=//")
DB_SERVER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_SERVER=" | sed "s/DB_SERVER=//")
MASTER_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^MASTER_KEY=" | sed "s/MASTER_KEY=//")
JOIN_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^JOIN_KEY=" | sed "s/JOIN_KEY=//")
LOCATION=$(cat /var/lib/cloud/instance/user-data.txt | grep "^LOCATION=" | sed "s/LOCATION=//")
ARTIFACTORY_URL=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_URL=" | sed "s/ARTIFACTORY_URL=//")
CLUSTER_NAME=$(cat /var/lib/cloud/instance/user-data.txt | grep "^CLUSTER_NAME=" | sed "s/CLUSTER_NAME=//")

export DEBIAN_FRONTEND=noninteractive

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
sudo add-apt-repository ppa:rmescandon/yq -y
sudo apt update -y
sudo apt install yq -y
sudo apt install nmap -y

# Create master.key on each node
sudo mkdir -p /opt/jfrog/xray/var/etc/security/
cat <<EOF >/opt/jfrog/xray/var/etc/security/master.key
${MASTER_KEY}
EOF

# Add Template Callhome to the Xray instance
cat <<EOF >>/opt/jfrog/xray/app/bin/xray.default
export PARTNER_ID=Partner/ACC-007221
export INTEGRATION_NAME=ARM_xray-template/1.0.0
EOF

# Verify if the app is deploying in GovCloud
regex_location_gov="usgov.*"
regex_location_dod="usdod.*"

if [[ "${LOCATION}" =~ $regex_location_gov ]] || [[ "${LOCATION}" =~ $regex_location_dod ]]; then
  DB_DOMAIN=usgovcloudapi.net
else
  DB_DOMAIN=azure.com
fi

# Modify system.yaml file
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.database.url postgres://${DB_SERVER}.postgres.database.${DB_DOMAIN}:5432/${DB_NAME}?sslmode=disable
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.database.username ${DB_USER}
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.database.actualUsername ${ACTUAL_DB_USER}
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.database.password ${DB_PASSWORD}
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.rabbitMq.password JFXR_RABBITMQ_COOKIE

# RabbitMQ HA configuration for VMSS
HOSTNAME=$(hostname -s)
ACTIVE_NODE_NAME=$(echo "$HOSTNAME" | sed 's/......$/000000/')
printenv

if [[ $HOSTNAME =~ 000000 ]];
then
  yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.rabbitMq.erlangCookie.value JFXR_RABBITMQ_COOKIE
else
  # Scan the subnet to verify if there are other Xray nodes
  # Get the first Xray node name, modify to met RabbitMQ requirements, add into system.yaml
  # Modify system.yaml to make a new RabbitMQ node able to connect to the cluster
  ACTIVE_NODE_NAME=$(nmap -sn $(hostname -i)/24 | grep -i ${CLUSTER_NAME} | sort | awk 'NR==1{print $5}')
  RABBITMQ_ACTIVE_NODE=$(cat /etc/hostname | sed 's/......$//g')$(echo $ACTIVE_NODE_NAME | cut -f1 -d"." | sed -e 's/\(^.*\)\(......$\)/\2/' | tr '[:lower:]' '[:upper:]')
  yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.rabbitMq.erlangCookie.value JFXR_RABBITMQ_COOKIE
  yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.rabbitMq.clean Y
  yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.rabbitMq.active.node.name ${RABBITMQ_ACTIVE_NODE}
fi
HOSTNAME=$(hostname -i)
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.jfrogUrl ${ARTIFACTORY_URL}
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.security.joinKey ${JOIN_KEY}
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.security.masterKeyFile /opt/jfrog/xray/var/etc/security/master.key
yq w -i /var/opt/jfrog/xray/etc/system.yaml shared.node.ip ${HOSTNAME}

chown xray:xray -R /opt/jfrog/xray/var/etc/security/* && chown xray:xray -R /opt/jfrog/xray/var/etc/security/


# Enable and start Xray service
sudo systemctl enable xray.service
sudo systemctl start xray.service
sudo systemctl restart xray.service
