# Ansible
This repo contains the Ansible collection for JFrog roles. These roles allow you to provision Artifactory for High-Availability using a Primary node and multiple Secondary nodes. Additionally, a Postgresql role is provided for installing an Artifactory Postgresql database.

## Roles Provided
### artifactory
The artifactory role installs the Artifactory Pro software onto the host. Per the Vars below, it will configure a node as primary or secondary. This role uses secondary roles artifactory-nginx to install nginx.

### artifactory-nginx-ssl
The artifactory-nginx-ssl role installs and configures nginx for SSL.

### postgres
The postgres role will install Postgresql software and configure a database and user to support an Artifactory or Xray server.

### xray
The xray role will install Xray software onto the host. An Artifactory server and Postgress database is required.

## Vars Required
The following Vars must be configured.

### databsase vars
* db_users: This is a list of database users to create. eg. db_users: - { db_user: "artifactory", db_password: "Art1fAct0ry" }
* dbs: This is the database to create. eg. dbs: - { db_name: "artifactory", db_owner: "artifactory" }

### artifactory vars
* artifactory_version: The version of Artifactory to install. eg. "7.4.1"
* master_key: This is the Artifactory Master Key.
* join_key: This is the Artifactory Join Key.
* db_download_url: This is the download URL for the JDBC driver for your database. eg. "https://jdbc.postgresql.org/download/postgresql-42.2.12.jar"
* db_type: This is the database type. eg. "postgresql"
* db_driver: This is the JDBC driver class. eg. "org.postgresql.Driver"
* db_url: This is the JDBC database url. eg. "jdbc:postgresql://10.0.0.120:5432/artifactory"
* db_user: The database user to configure. eg. "artifactory"
* db_password: The database password to configure. "Art1fact0ry"
* server_name: This is the server name. eg. "artifactory.54.175.51.178.xip.io"

### primary vars
* artifactory_is_primary: For the primary node this must be set to **true**.
* artifactory_license1 - 5: These are the cluster licenses.

### secondary vars
* artifactory_is_primary: For the secondary node(s) this must be set to **false**.

### ssl vars (Used with artifactory-nginx-ssl role)
* certificate: This is the SSL cert.
* certificate_key: This is the SSL private key.

### xray vars
* xray_version: The version of Artifactory to install. eg. "3.3.0"
* jfrog_url: This is the URL to the Artifactory base URL. eg. "http://ec2-54-237-207-135.compute-1.amazonaws.com"
* master_key: This is the Artifactory Master Key.
* join_key: This is the Artifactory Join Key.
* db_type: This is the database type. eg. "postgresql"
* db_driver: This is the JDBC driver class. eg. "org.postgresql.Driver"
* db_url: This is the database url. eg. "postgres://10.0.0.59:5432/xraydb?sslmode=disable"
* db_user: The database user to configure. eg. "xray"
* db_password: The database password to configure. "xray"

## Example Inventory and Playbooks
Example playbooks are located in the [project](../project) directory. This directory contains several example inventory and plaaybooks for different Artifactory, HA and Xray architectures.

## Executing a Playbook
```
ansible-playbook -i <hosts file> <playbook file>

eg.
 ansible-playbook -i example-playbooks/rt-xray-ha/hosts.yml example-playbooks/rt-xray-ha/playbook.yml
```

## Bastion Hosts
In many cases, you may want to run this Ansible collection through a Bastion host to provision JFrog servers. You can include the following Var for a host or group of hosts:

```
ansible_ssh_common_args: '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -A user@host -W %h:%p"'

eg.
ansible_ssh_common_args: '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -A ubuntu@{{ azureDeployment.deployment.outputs.lbIp.value }} -W %h:%p"'
```