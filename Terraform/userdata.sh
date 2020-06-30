#!/bin/bash

yum update -y
yum install -y java-1.8.0>> /tmp/yum-java8.log
alternatives --set java /usr/lib/jvm/jre-1.8.0-openjdk.x86_64/bin/java
yum -y remove java-1.7.0-openjdk>> /tmp/yum-java7.log 2>&1

##Install Artifactory
wget https://bintray.com/jfrog/artifactory-pro-rpms/rpm -O bintray-jfrog-artifactory-pro-rpms.repo
mv bintray-jfrog-artifactory-pro-rpms.repo /etc/yum.repos.d/
sleep 10
yum install -y jfrog-artifactory-pro-${artifactory_version}>> /tmp/yum-artifactory.log 2>&1
yum install -y nginx>> /tmp/yum-nginx.log 2>&1
curl -L -o  /opt/jfrog/artifactory/tomcat/lib/mysql-connector-java-5.1.38.jar https://bintray.com/artifact/download/bintray/jcenter/mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar
openssl req -nodes -x509 -newkey rsa:4096 -keyout /etc/pki/tls/private/example.key -out /etc/pki/tls/certs/example.pem -days 356 -subj "/C=US/ST=California/L=SantaClara/O=IT/CN=*.localhost"

cat <<EOF >/var/opt/jfrog/artifactory/etc/binarystore.xml
<config version="2">
    <chain> <!--template="cluster-s3"-->
        <provider id="cache-fs-eventual-s3" type="cache-fs">
            <provider id="sharding-cluster-eventual-s3" type="sharding-cluster">
                <sub-provider id="eventual-cluster-s3" type="eventual-cluster">
                    <provider id="retry-s3" type="retry">
                        <provider id="s3" type="s3"/>
                    </provider>
                </sub-provider>
                <dynamic-provider id="remote-s3" type="remote"/>
            </provider>
        </provider>
    </chain>

    <provider id="sharding-cluster-eventual-s3" type="sharding-cluster">
        <readBehavior>crossNetworkStrategy</readBehavior>
        <writeBehavior>crossNetworkStrategy</writeBehavior>
        <redundancy>2</redundancy>
        <property name="zones" value="local,remote"/>
    </provider>

    <provider id="remote-s3" type="remote">
        <zone>remote</zone>
    </provider>

    <provider id="eventual-cluster-s3" type="eventual-cluster">
        <zone>local</zone>
    </provider>
    <provider id="s3" type="s3">
       <endpoint>s3.dualstack.${s3_bucket_region}.amazonaws.com</endpoint>
       <identity>${s3_access_key}</identity>
       <credential>${s3_secret_key}</credential>
       <bucketName>${s3_bucket_name}</bucketName>
    </provider>
</config>
EOF

cat <<EOF >/var/opt/jfrog/artifactory/etc/db.properties
  type=mysql
  driver=com.mysql.jdbc.Driver
  url=jdbc:mysql://${db_url}/${db_name}??characterEncoding=UTF-8&elideSetAutoCommits=true
  username=${db_user}
  password=${db_password}
EOF

mkdir -p /var/opt/jfrog/artifactory/etc/security

cat <<EOF >/var/opt/jfrog/artifactory/etc/security/master.key
${master_key}
EOF

cat <<EOF >/var/opt/jfrog/artifactory/etc/artifactory.cluster.license
${artifactory_license_1}

${artifactory_license_2}

${artifactory_license_3}

${artifactory_license_4}

${artifactory_license_5}
EOF

cat <<EOF >/var/opt/jfrog/artifactory/etc/ha-node.properties
  node.id=art1
  artifactory.ha.data.dir=/var/opt/jfrog/artifactory/data
  context.url=http://127.0.0.1:8081/artifactory
  membership.port=10001
  hazelcast.interface=172.25.0.3
  primary=${ISPRIMARY}
EOF

cat <<EOF >/etc/pki/tls/certs/result.pem
${ssl_certificate}
EOF

cat <<EOF >/etc/pki/tls/private/result.key
${ssl_certificate_key}
EOF

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
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
    '\$status \$body_bytes_sent "\$http_referer" '
    '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    #keepalive_timeout  0;
    keepalive_timeout  65;
    }
EOF

cat <<EOF >/etc/nginx/conf.d/artifactory.conf
ssl_certificate      /etc/pki/tls/certs/cert.pem;
ssl_certificate_key  /etc/pki/tls/private/cert.key;
ssl_session_cache shared:SSL:1m;
ssl_prefer_server_ciphers   on;
## server configuration
server {
  listen 443 ssl;
  listen 80 ;
  server_name ~(?<repo>.+)\\.${certificate_domain} ${artifactory_server_name}.${certificate_domain};
  if (\$http_x_forwarded_proto = '') {
    set \$http_x_forwarded_proto  \$scheme;
  }
  ## Application specific logs
  ## access_log /var/log/nginx/artifactory-access.log timing;
  ## error_log /var/log/nginx/artifactory-error.log;
  rewrite ^/$ /artifactory/webapp/ redirect;
  rewrite ^/artifactory/?(/webapp)?$ /artifactory/webapp/ redirect;
  rewrite ^/(v1|v2)/(.*) /artifactory/api/docker/\$repo/\$1/\$2;
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

mkdir -p /var/opt/jfrog/artifactory/etc/info
cat <<EOF >/var/opt/jfrog/artifactory/etc/info/installer-info.json
{
  "productId": "Terraform_artifactory-ha/1.0.0",
  "features": [
  {
    "featureId": "Partner/ACC-007450"
  }
  ]
}
EOF

cat /etc/pki/tls/certs/result.pem | sed 's/CERTIFICATE----- /CERTIFICATE-----\n/g' | sed 's/-----END/\n-----END/' > temp.pem
mv -f temp.pem /etc/pki/tls/certs/cert.pem
cat /etc/pki/tls/private/result.key | sed 's/KEY----- /KEY-----\n/g' | sed 's/-----END/\n-----END/'  > temp.key
mv -f temp.key /etc/pki/tls/private/cert.key
echo "artifactory.ping.allowUnauthenticated=true" >> /var/opt/jfrog/artifactory/etc/artifactory.system.properties
echo "export JAVA_OPTIONS=\"${EXTRA_JAVA_OPTS}\"" >> /var/opt/jfrog/artifactory/etc/default
sed -i -e "s/art1/art-$(date +%s$RANDOM)/" /var/opt/jfrog/artifactory/etc/ha-node.properties
sed -i -e "s/127.0.0.1/$(curl http://169.254.169.254/latest/meta-data/public-ipv4)/" /var/opt/jfrog/artifactory/etc/ha-node.properties
sed -i -e "s/172.25.0.3/$(curl http://169.254.169.254/latest/meta-data/local-ipv4)/" /var/opt/jfrog/artifactory/etc/ha-node.properties
chown artifactory:artifactory -R /var/opt/jfrog/artifactory/etc/* && chown artifactory:artifactory -R /var/opt/jfrog/artifactory/*  && chown artifactory:artifactory -R /var/opt/jfrog/artifactory/etc/security
service artifactory start
service nginx start
