#!/bin/bash

# Script stdout and stderr are stored in /var/lib/waagent/custom-script/download on the VM
DB_URL=$(cat /var/lib/cloud/instance/user-data.txt | grep "^JDBC_STR" | sed "s/JDBC_STR=//")
DB_NAME=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_NAME=" | sed "s/DB_NAME=//")
DB_USER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_USER=" | sed "s/DB_ADMIN_USER=//")
DB_TYPE=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_TYPE=" | sed "s/DB_TYPE=//")
DB_PASSWORD=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_PASSWD=" | sed "s/DB_ADMIN_PASSWD=//")
STORAGE_ACCT=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_ACT_NAME=" | sed "s/STO_ACT_NAME=//")
STORAGE_CONTAINER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_CTR_NAME=" | sed "s/STO_CTR_NAME=//")
STORAGE_ACCT_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_ACT_KEY=" | sed "s/STO_ACT_KEY=//")
ARTIFACTORY_VERSION=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_VERSION=" | sed "s/ARTIFACTORY_VERSION=//")
CERTIFICATE=$(cat /var/lib/cloud/instance/user-data.txt | grep "^CERTIFICATE=" | sed "s/CERTIFICATE=//")
CERTIFICATE_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^CERTIFICATE_KEY=" | sed "s/CERTIFICATE_KEY=//")
MASTER_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^MASTER_KEY=" | sed "s/MASTER_KEY=//")
IS_PRIMARY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^IS_PRIMARY=" | sed "s/IS_PRIMARY=//")
ARTIFACTORY_LICENSE_1=$(cat /var/lib/cloud/instance/user-data.txt | grep "^LICENSE1=" | sed "s/LICENSE1=//")
ARTIFACTORY_LICENSE_2=$(cat /var/lib/cloud/instance/user-data.txt | grep "^LICENSE2=" | sed "s/LICENSE2=//")
ARTIFACTORY_LICENSE_3=$(cat /var/lib/cloud/instance/user-data.txt | grep "^LICENSE3=" | sed "s/LICENSE3=//")
ARTIFACTORY_LICENSE_4=$(cat /var/lib/cloud/instance/user-data.txt | grep "^LICENSE4=" | sed "s/LICENSE4=//")
ARTIFACTORY_LICENSE_5=$(cat /var/lib/cloud/instance/user-data.txt | grep "^LICENSE5=" | sed "s/LICENSE5=//")
export DEBIAN_FRONTEND=noninteractive

#Generate Self-Signed Cert
mkdir -p /etc/pki/tls/private/ /etc/pki/tls/certs/
openssl req -nodes -x509 -newkey rsa:4096 -keyout /etc/pki/tls/private/example.key -out /etc/pki/tls/certs/example.pem -days 356 -subj "/C=US/ST=California/L=SantaClara/O=IT/CN=*.localhost"

# Install Postgresql driver
curl --retry 5 -L -o /opt/jfrog/artifactory/app/artifactory/tomcat/lib/postgresql-9.4.1212.jar https://jdbc.postgresql.org/download/postgresql-9.4.1212.jar >> /tmp/install-databse-driver.log 2>&1

CERTIFICATE_DOMAIN=$(cat /var/lib/cloud/instance/user-data.txt | grep "^CERTIFICATE_DOMAIN=" | sed "s/CERTIFICATE_DOMAIN=//")
[ -z "$CERTIFICATE_DOMAIN" ] && CERTIFICATE_DOMAIN=artifactory

ARTIFACTORY_SERVER_NAME=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_SERVER_NAME=" | sed "s/ARTIFACTORY_SERVER_NAME=//")
[ -z "$ARTIFACTORY_SERVER_NAME" ] && ARTIFACTORY_SERVER_NAME=artifactory

#Configuring nginx
rm /etc/nginx/sites-enabled/default

cat <<EOF >/etc/nginx/nginx.conf
  #user  nobody;
  worker_processes  1;
  error_log  /var/log/nginx/error.log  info;
  #pid        logs/nginx.pid;
  events {
    worker_connections  1024;
  }

  http {
    include       mime.types;
    variables_hash_max_size 1024;
    variables_hash_bucket_size 64;
    server_names_hash_max_size 4096;
    server_names_hash_bucket_size 128;
    types_hash_max_size 2048;
    types_hash_bucket_size 64;
    proxy_read_timeout 2400s;
    client_header_timeout 2400s;
    client_body_timeout 2400s;
    proxy_connect_timeout 75s;
    proxy_send_timeout 2400s;
    proxy_buffer_size 32k;
    proxy_buffers 40 32k;
    proxy_busy_buffers_size 64k;
    proxy_temp_file_write_size 250m;
    proxy_http_version 1.1;
    client_body_buffer_size 128k;

    include    /etc/nginx/conf.d/*.conf;
    default_type  application/octet-stream;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    '$status $body_bytes_sent "$http_referer" '
    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    #keepalive_timeout  0;
    keepalive_timeout  65;
    }
EOF

if [[ -n "${CERTIFICATE}" ]] || [[ -n "${CERTIFICATE_KEY}" ]]; then

cat <<EOF >/etc/nginx/conf.d/artifactory.conf
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_certificate      /etc/pki/tls/certs/cert.pem;
ssl_certificate_key  /etc/pki/tls/private/cert.key;
ssl_session_cache shared:SSL:1m;
ssl_prefer_server_ciphers   on;
## server configuration
server {
  listen 443 ssl;
  listen 80 ;
  server_name ~(?<repo>.+)\\.${CERTIFICATE_DOMAIN} artifactory ${ARTIFACTORY_SERVER_NAME}.${CERTIFICATE_DOMAIN};
  if (\$http_x_forwarded_proto = '') {
    set \$http_x_forwarded_proto  \$scheme;
  }
  ## Application specific logs
  ## access_log /var/log/nginx/artifactory-access.log timing;
  ## error_log /var/log/nginx/artifactory-error.log;
  rewrite ^/$ /ui/ redirect;
  rewrite ^/ui$ /ui/ redirect;
  chunked_transfer_encoding on;
  client_max_body_size 0;
  location / {
    proxy_read_timeout  2400;
    proxy_pass_header   Server;
    proxy_cookie_path   ~*^/.* /;
    proxy_pass          http://127.0.0.1:8082;
    proxy_next_upstream error timeout non_idempotent;
    proxy_next_upstream_tries    1;
    proxy_set_header    X-JFrog-Override-Base-Url \$http_x_forwarded_proto://\$host:\$server_port;
    proxy_set_header    X-Forwarded-Port  \$server_port;
    proxy_set_header    X-Forwarded-Proto \$http_x_forwarded_proto;
    proxy_set_header    Host              \$http_host;
    proxy_set_header    X-Forwarded-For   \$proxy_add_x_forwarded_for;

          location ~ ^/artifactory/ {
            proxy_pass    http://127.0.0.1:8081;
        }
    }
}
EOF
else

cat <<EOF >/etc/nginx/conf.d/artifactory.conf
## server configuration
server {
  listen 80 ;
  server_name ~(?<repo>.+)\\.${CERTIFICATE_DOMAIN} artifactory ${ARTIFACTORY_SERVER_NAME}.${CERTIFICATE_DOMAIN};
  if (\$http_x_forwarded_proto = '') {
    set \$http_x_forwarded_proto  \$scheme;
  }
  ## Application specific logs
  ## access_log /var/log/nginx/artifactory-access.log timing;
  ## error_log /var/log/nginx/artifactory-error.log;
  rewrite ^/$ /ui/ redirect;
  rewrite ^/ui$ /ui/ redirect;
  chunked_transfer_encoding on;
  client_max_body_size 0;
  location / {
    proxy_read_timeout  2400;
    proxy_pass_header   Server;
    proxy_cookie_path   ~*^/.* /;
    proxy_pass          http://127.0.0.1:8082;
    proxy_next_upstream error timeout non_idempotent;
    proxy_next_upstream_tries    1;
    proxy_set_header    X-JFrog-Override-Base-Url \$http_x_forwarded_proto://\$host:\$server_port;
    proxy_set_header    X-Forwarded-Port  \$server_port;
    proxy_set_header    X-Forwarded-Proto \$http_x_forwarded_proto;
    proxy_set_header    Host              \$http_host;
    proxy_set_header    X-Forwarded-For   \$proxy_add_x_forwarded_for;

          location ~ ^/artifactory/ {
            proxy_pass    http://127.0.0.1:8081;
        }
    }
}
EOF

fi

mkdir -p /opt/jfrog/artifactory/var/etc/artifactory/
cat <<EOF >/opt/jfrog/artifactory/var/etc/artifactory/artifactory.cluster.license
${ARTIFACTORY_LICENSE_1}

${ARTIFACTORY_LICENSE_2}

${ARTIFACTORY_LICENSE_3}

${ARTIFACTORY_LICENSE_4}

${ARTIFACTORY_LICENSE_5}
EOF

HOSTNAME=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')

if [ "${IS_PRIMARY}" = "true" ]; then
    NODE_NAME=art-primary
else
    NODE_NAME=art-$(date +%s$RANDOM)
fi

# Java options
EXTRA_JAVA_OPTS=$(cat /var/lib/cloud/instance/user-data.txt | grep "^EXTRA_JAVA_OPTS=" | sed "s/EXTRA_JAVA_OPTS=//")
sed -i -e "s/#extraJavaOpts: \"-Xms512m -Xmx2g\"/extraJavaOpts: ${EXTRA_JAVA_OPTS}/" /var/opt/jfrog/artifactory/etc/system.yaml

# Node settings
HOSTNAME=$(hostname -i)
sed -i -e "s/#id: \"art1\"/id: \"${NODE_NAME}\"/" /var/opt/jfrog/artifactory/etc/system.yaml
sed -i -e "s/#ip:/ip: ${HOSTNAME}/" /var/opt/jfrog/artifactory/etc/system.yaml
sed -i -e "s/#primary: true/primary: ${IS_PRIMARY}/" /var/opt/jfrog/artifactory/etc/system.yaml
sed -i -e "s/#haEnabled:/haEnabled:/" /var/opt/jfrog/artifactory/etc/system.yaml


if [[ $DB_TYPE =~ "MSSQL" ]]; then
    # Set MS SQL configuration
    cat <<EOF >>/var/opt/jfrog/artifactory/etc/system.yaml
    ## One of: mysql, oracle, mssql, postgresql, mariadb
    ## Default: Embedded derby
    ## Example for mssql
      type: mssql
      driver: com.microsoft.sqlserver.jdbc.SQLServerDriver
      url: ${DB_URL};databaseName=${DB_NAME};sendStringParametersAsUnicode=false;applicationName=Artifactory Binary Repository
      username: ${DB_USER}
      password: ${DB_PASSWORD}

EOF
elif [[ $DB_TYPE =~ "Postgresql" ]]; then
   # Set Postgresql settings (add if/else for Postgres/MSSQL) ATTENTION - RT VM 7.5.5 doesn't have Postgres driver!!
   cat <<EOF >>/var/opt/jfrog/artifactory/etc/system.yaml
    ## One of: mysql, oracle, mssql, postgresql, mariadb
    ## Default: Embedded derby
    ## Example for postgresql
      type: postgresql
      driver: org.postgresql.Driver
      url: ${DB_URL}/${DB_NAME}
      username: ${DB_USER}
      password: ${DB_PASSWORD}

EOF
fi

# Create master.key on each node
mkdir -p /opt/jfrog/artifactory/var/etc/security/
cat <<EOF >/opt/jfrog/artifactory/var/etc/security/master.key
${MASTER_KEY}
EOF

# Azure Blob Storage configuration
# https://www.jfrog.com/confluence/display/JFROG/Configuring+the+Filestore#ConfiguringtheFilestore-AzureBlobStorageClusterBinaryProvider
mkdir -p /var/opt/jfrog/artifactory/etc/artifactory/
cat <<EOF >/var/opt/jfrog/artifactory/etc/artifactory/binarystore.xml
<config version="2">
    <chain template="cluster-azure-blob-storage"/>
    <provider id="azure-blob-storage" type="azure-blob-storage">
        <accountName>${STORAGE_ACCT}</accountName>
        <accountKey>${STORAGE_ACCT_KEY}</accountKey>
        <endpoint>https://${STORAGE_ACCT}.blob.core.windows.net/</endpoint>
        <containerName>${STORAGE_CONTAINER}</containerName>
    </provider>
</config>
EOF

if [[ -n "${CERTIFICATE}" ]] || [[ -n "${CERTIFICATE_KEY}" ]]; then
cat <<EOF >/tmp/temp.pem
${CERTIFICATE}
EOF
cat /tmp/temp.pem | sed 's/CERTIFICATE----- /&\n/g' | sed 's/ -----END/\n-----END/g' | awk '{if($0 ~ /----/) {print;} else { gsub(/ /,"\n");print;}}' > /etc/pki/tls/certs/cert.pem
    rm /tmp/temp.pem

cat <<EOF >/tmp/temp.key
${CERTIFICATE_KEY}
EOF
cat /tmp/temp.key | sed 's/KEY----- /&\n/' | sed 's/ -----END/\n-----END/' | awk '{if($0 ~ /----/) {print;} else { gsub(/ /,"\n");print;}}' > /etc/pki/tls/private/cert.key
    rm /tmp/temp.key
fi

chown artifactory:artifactory -R /var/opt/jfrog/artifactory/*  && chown artifactory:artifactory -R /var/opt/jfrog/artifactory/etc/security && chown artifactory:artifactory -R /var/opt/jfrog/artifactory/etc/*

# start Artifactory
sleep 120
systemctl start artifactory
systemctl start nginx
nginx -s reload
echo "INFO: Artifactory HA installation completed."
echo ""
