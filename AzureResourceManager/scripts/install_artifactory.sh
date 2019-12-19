#!/bin/bash
DB_URL=$(cat /var/lib/cloud/instance/user-data.txt | grep "^JDBC_STR" | sed "s/JDBC_STR=//")
DB_NAME=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_NAME=" | sed "s/DB_NAME=//")
DB_USER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_USER=" | sed "s/DB_ADMIN_USER=//")
DB_PASSWORD=$(cat /var/lib/cloud/instance/user-data.txt | grep "^DB_ADMIN_PASSWD=" | sed "s/DB_ADMIN_PASSWD=//")
STORAGE_ACCT=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_ACT_NAME=" | sed "s/STO_ACT_NAME=//")
STORAGE_CONTAINER=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_CTR_NAME=" | sed "s/STO_CTR_NAME=//")
STORAGE_ACCT_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^STO_ACT_KEY=" | sed "s/STO_ACT_KEY=//")
ARTIFACTORY_EDITION=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_EDITION=" | sed "s/ARTIFACTORY_EDITION=//")
ARTIFACTORY_VERSION=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_VERSION=" | sed "s/ARTIFACTORY_VERSION=//")
MASTER_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^MASTER_KEY=" | sed "s/MASTER_KEY=//")
JFROG_JOIN_KEY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^JOIN_KEY=" | sed "s/JOIN_KEY=//")
IS_PRIMARY=$(cat /var/lib/cloud/instance/user-data.txt | grep "^IS_PRIMARY=" | sed "s/IS_PRIMARY=//")

#disable firewalld, also disable selinux. Both block traffic from load balancer. 
systemctl stop firewalld
setenforce Permissive

# install the wget and curl
yum -y install wget curl>> /tmp/install-curl.log 2>&1

yum -y install java-1.8.0-openjdk >> /tmp/install-java.log 2>&1
#yum -y install java-11-openjdk >> /tmp/install-java.log 2>&1

#Generate Self-Signed Cert
mkdir -p /etc/pki/tls/private/ /etc/pki/tls/certs/
openssl req -nodes -x509 -newkey rsa:4096 -keyout /etc/pki/tls/private/example.key -out /etc/pki/tls/certs/example.pem -days 356 -subj "/C=US/ST=California/L=SantaClara/O=IT/CN=*.localhost"

setenforce 0
sed -i -e "s/SELINUX=.*/SELINUX=permissive/" /etc/sysconfig/selinux
wget https://bintray.com/jfrog/artifactory-pro-rpms/rpm -O bintray-jfrog-artifactory-pro-rpms.repo
mv bintray-jfrog-artifactory-pro-rpms.repo /etc/yum.repos.d/
wget https://bintray.com/jfrog/artifactory-rpms/rpm     -O bintray-jfrog-artifactory-rpms.repo;
mv bintray-jfrog-artifactory-rpms.repo    /etc/yum.repos.d/

yum -y install ${ARTIFACTORY_EDITION}-${ARTIFACTORY_VERSION} >> /tmp/install-artifactory.log 2>&1

cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/rhel/7/\$basearch/
gpgcheck=0
enabled=1
EOF
yum -y install nginx>> /tmp/install-nginx.log 2>&1

#Install database drivers
curl -L -o  /opt/jfrog/artifactory/tomcat/lib/mysql-connector-java-5.1.38.jar https://bintray.com/artifact/download/bintray/jcenter/mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar
curl -L -o  /opt/jfrog/artifactory/tomcat/lib/mssql-jdbc-6.2.1.jre8.jar https://bintray.com/artifact/download/bintray/jcenter/com/microsoft/sqlserver/mssql-jdbc/6.2.1.jre8/mssql-jdbc-6.2.1.jre8.jar
curl -L -o  /opt/jfrog/artifactory/tomcat/lib/postgresql-9.4.1212.jar https://jdbc.postgresql.org/download/postgresql-9.4.1212.jar

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

rm /etc/nginx/conf.d/default.conf


mkdir -p /var/opt/jfrog/artifactory/etc/security

cat <<EOF >/var/opt/jfrog/artifactory/etc/security/master.key
${MASTER_KEY}
EOF

# in case of JCR or OSS, use non-ha mode, also use derby, also do not create binary store xml
cat <<EOF >/var/opt/jfrog/artifactory/etc/db.properties
type=mssql
driver=com.microsoft.sqlserver.jdbc.SQLServerDriver
url=${DB_URL};databaseName=${DB_NAME};sendStringParametersAsUnicode=false;applicationName=Artifactory Binary Repository
username=${DB_USER}
password=${DB_PASSWORD}
EOF
cat <<EOF >/var/opt/jfrog/artifactory/etc/binarystore.xml
<config version="2">
    <chain>
       <provider id="cache-fs-eventual-azure-blob-storage" type="cache-fs">
           <provider id="sharding-cluster-eventual-azure-blob-storage" type="sharding-cluster">
               <sub-provider id="eventual-cluster-azure-blob-storage" type="eventual-cluster">
                   <provider id="retry-azure-blob-storage" type="retry">
                       <provider id="azure-blob-storage" type="azure-blob-storage"/>
                   </provider>
               </sub-provider>
               <dynamic-provider id="remote-azure-blob-storage" type="remote"/>
           </provider>
       </provider>
   </chain>

    <!-- cluster eventual Azure Blob Storage Service default chain -->
    <provider id="sharding-cluster-eventual-azure-blob-storage" type="sharding-cluster">
        <readBehavior>crossNetworkStrategy</readBehavior>
        <writeBehavior>crossNetworkStrategy</writeBehavior>
        <redundancy>2</redundancy>
        <lenientLimit>1</lenientLimit>
        <property name="zones" value="local,remote"/>
    </provider>

    <provider id="remote-azure-blob-storage" type="remote">
        <zone>remote</zone>
    </provider>

    <provider id="eventual-cluster-azure-blob-storage" type="eventual-cluster">
        <zone>local</zone>
    </provider>

    <!--cluster eventual template-->
    <provider id="azure-blob-storage" type="azure-blob-storage">
        <accountName>${STORAGE_ACCT}</accountName>
        <accountKey>${STORAGE_ACCT_KEY}</accountKey>
        <endpoint>https://${STORAGE_ACCT}.blob.core.windows.net/</endpoint>
        <containerName>${STORAGE_CONTAINER}</containerName>
    </provider>
</config>
EOF

# begin JCR specific setup

cat <<EOF >/etc/nginx/conf.d/artifactory.conf
ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
ssl_certificate      /etc/pki/tls/certs/cert.pem;
ssl_certificate_key  /etc/pki/tls/private/cert.key;
ssl_session_cache shared:SSL:1m;
ssl_prefer_server_ciphers   on;
## server configuration
server {
  listen 443 ssl;
  listen 80 ;
  server_name ~(?<repo>.+)\\.${CERTIFICATE_DOMAIN} artifactory ${ARTIFACTORY_SERVER_NAME}.${CERTIFICATE_DOMAIN} ${CERTIFICATE_DOMAIN};
  if (\$http_x_forwarded_proto = '') {
    set \$http_x_forwarded_proto  \$scheme;
  }
  ## Application specific logs
  ## access_log /var/log/nginx/artifactory-access.log timing;
  ## error_log /var/log/nginx/artifactory-error.log;
  rewrite ^/$ /artifactory/webapp/ redirect;
  rewrite ^/artifactory/?(/webapp)?$ /artifactory/webapp/ redirect;

  rewrite ^/(v2)/(.*) /artifactory/\$1/\$2;

  chunked_transfer_encoding on;
  client_max_body_size 0;
  location /artifactory/ {
    proxy_read_timeout  2400;
    proxy_pass_header   Server;
    proxy_cookie_path   ~*^/.* /;

    proxy_pass          http://127.0.0.1:8081/artifactory/;
    proxy_set_header    X-Artifactory-Override-Base-Url \$http_x_forwarded_proto://\$host:\$server_port/artifactory;
    proxy_set_header    X-Forwarded-Port  \$server_port;
    proxy_set_header    X-Forwarded-Proto \$http_x_forwarded_proto;
    proxy_set_header    Host              \$http_host;
    proxy_set_header    X-Forwarded-For   \$proxy_add_x_forwarded_for;
   }
}
EOF

# end JCR specific setup


# callhome metadata
mkdir -p /var/opt/jfrog/artifactory/etc/info
cat <<EOF >/var/opt/jfrog/artifactory/etc/info/installer-info.json
{
  "productId": "JFrogInstaller_AzureMP/${ARTIFACTORY_VERSION}",
  "features": [
    {
      "featureId": "ArtifactoryVersion/${ARTIFACTORY_EDITION}-${ARTIFACTORY_VERSION}"
    },
    {
      "featureId": "Platform/azure-mp-vm-jcr"
    }
  ]
}
EOF

HOSTNAME=$(hostname -i)
sed -i -e "s/art1/art-$(date +%s$RANDOM)/" /var/opt/jfrog/artifactory/etc/ha-node.properties
sed -i -e "s/127.0.0.1/$HOSTNAME/" /var/opt/jfrog/artifactory/etc/ha-node.properties
sed -i -e "s/172.25.0.3/$HOSTNAME/" /var/opt/jfrog/artifactory/etc/ha-node.properties

cat /var/lib/cloud/instance/user-data.txt | grep "^CERTIFICATE=" | sed "s/CERTIFICATE=//" > /tmp/temp.pem
cat /tmp/temp.pem | sed 's/CERTIFICATE----- /&\n/g' | sed 's/ -----END/\n-----END/g' | awk '{if($0 ~ /----/) {print;} else { gsub(/ /,"\n");print;}}' > /etc/pki/tls/certs/cert.pem
rm /tmp/temp.pem

cat /var/lib/cloud/instance/user-data.txt | grep "^CERTIFICATE_KEY=" | sed "s/CERTIFICATE_KEY=//" > /tmp/temp.key
cat /tmp/temp.key | sed 's/KEY----- /&\n/' | sed 's/ -----END/\n-----END/' | awk '{if($0 ~ /----/) {print;} else { gsub(/ /,"\n");print;}}' > /etc/pki/tls/private/cert.key
rm /tmp/temp.key

echo "artifactory.ping.allowUnauthenticated=true" >> /var/opt/jfrog/artifactory/etc/artifactory.system.properties
EXTRA_JAVA_OPTS=$(cat /var/lib/cloud/instance/user-data.txt | grep "^EXTRA_JAVA_OPTS=" | sed "s/EXTRA_JAVA_OPTS=//")
[ -z "$EXTRA_JAVA_OPTS" ] && EXTRA_JAVA_OPTS='-server -Xms2g -Xmx6g -Xss256k -XX:+UseG1GC -XX:OnOutOfMemoryError="kill -9 %p"'
echo "export JAVA_OPTIONS=\"${EXTRA_JAVA_OPTS}\"" >> /var/opt/jfrog/artifactory/etc/default
chown artifactory:artifactory -R /var/opt/jfrog/artifactory/*  && chown artifactory:artifactory -R /var/opt/jfrog/artifactory/etc/security && chown artifactory:artifactory -R /var/opt/jfrog/artifactory/etc/*

# start Artifactory
sleep $((RANDOM % 120))
service artifactory start
service nginx start
nginx -s reload
echo "INFO: Artifactory JCR installation completed."

