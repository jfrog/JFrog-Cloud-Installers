# JFrog Ansible Installers Collection
This collection provides roles for installing Artifactory and Xray. Additionally, it provides optional SSL and Postgresql roles if these are needed for your deployment.

## Roles Provided
### artifactory
The artifactory role installs the Artifactory Pro software onto the host. Per the Vars below, it will configure a node as primary or secondary. This role uses secondary roles artifactory_nginx to install nginx.

### artifactory_nginx_ssl
The artifactory_nginx_ssl role installs and configures nginx for SSL.

### postgres
The postgres role will install Postgresql software and configure a database and user to support an Artifactory or Xray server.

### xray
The xray role will install Xray software onto the host. An Artifactory server and Postgress database is required.

## Vars Required
The following Vars must be configured.

### databsase vars
* _db_users_: This is a list of database users to create. eg. db_users: - { db_user: "artifactory", db_password: "Art1fAct0ry" }
* _dbs_: This is the database to create. eg. dbs: - { db_name: "artifactory", db_owner: "artifactory" }

### artifactory vars
* _artifactory_version_: The version of Artifactory to install. eg. "7.4.1"
* _master_key_: This is the Artifactory [Master Key](https://www.jfrog.com/confluence/display/JFROG/Managing+Keys). See below to [autogenerate this key](#autogenerating-master-and-join-keys).
* _join_key_: This is the Artifactory [Join Key](https://www.jfrog.com/confluence/display/JFROG/Managing+Keys). See below to [autogenerate this key](#autogenerating-master-and-join-keys).
* _db_download_url_: This is the download URL for the JDBC driver for your database. eg. "https://jdbc.postgresql.org/download/postgresql-42.2.12.jar"
* _db_type_: This is the database type. eg. "postgresql"
* _db_driver_: This is the JDBC driver class. eg. "org.postgresql.Driver"
* _db_url_: This is the JDBC database url. eg. "jdbc:postgresql://10.0.0.120:5432/artifactory"
* _db_user_: The database user to configure. eg. "artifactory"
* _db_password_: The database password to configure. "Art1fact0ry"
* _server_name_: This is the server name. eg. "artifactory.54.175.51.178.xip.io"
* _system_file_: Your own [system YAML](https://www.jfrog.com/confluence/display/JFROG/System+YAML+Configuration+File) file can be specified and used. **If specified, this file will be used rather than constructing a file from the parameters above.**
* _binary_store_file_: Your own [binary store file](https://www.jfrog.com/confluence/display/JFROG/Configuring+the+Filestore) can be used. If specified, the default cluster-file-system will not be used.

### primary vars (vars used by the primary Artifactory server)
* _artifactory_is_primary_: For the primary node this must be set to **true**.
* _artifactory_license1 - 5_: These are the cluster licenses.
* _artifactory_license_file_: Your own license file can be used. **If specified, a license file constructed from the licenses above will not be used.**

### secondary vars (vars used by the secondary Artifactory server)
* _artifactory_is_primary_: For the secondary node(s) this must be set to **false**.

### ssl vars (Used with artifactory_nginx_ssl role)
* _certificate_: This is the SSL cert.
* _certificate_key_: This is the SSL private key.

### xray vars
* _xray_version_: The version of Artifactory to install. eg. "3.3.0"
* _jfrog_url_: This is the URL to the Artifactory base URL. eg. "http://ec2-54-237-207-135.compute-1.amazonaws.com"
* _master_key_: This is the Artifactory [Master Key](https://www.jfrog.com/confluence/display/JFROG/Managing+Keys). See below to [autogenerate this key](#autogenerating-master-and-join-keys).
* _join_key_: This is the Artifactory [Join Key](https://www.jfrog.com/confluence/display/JFROG/Managing+Keys). See below to [autogenerate this key](#autogenerating-master-and-join-keys).
* _db_type_: This is the database type. eg. "postgresql"
* _db_driver_: This is the JDBC driver class. eg. "org.postgresql.Driver"
* _db_url_: This is the database url. eg. "postgres://10.0.0.59:5432/xraydb?sslmode=disable"
* _db_user_: The database user to configure. eg. "xray"
* _db_password_: The database password to configure. "xray"
* _system_file_: Your own [system YAML](https://www.jfrog.com/confluence/display/JFROG/System+YAML+Configuration+File) file can be specified and used. If specified, this file will be used rather than constructing a file from the parameters above.

## Example Inventory and Playbooks
Example playbooks are located in the [examples](../examples) directory. This directory contains several example inventory and playbooks for different Artifactory, HA and Xray architectures.

## Executing a Playbook
```
ansible-playbook -i <hosts file> <playbook file>
```

## Autogenerating Master and Join Keys
You may want to auto-generate your master amd join keys and apply it to all the nodes.

```
ansible-playbook -i hosts.yml playbook.yml --extra-vars "master_key=$(openssl rand -hex 16) join_key=$(openssl rand -hex 16)"
```

## Using [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) to Encrypt Vars
Some vars you may want to keep secret. You may put these vars into a separate file and encrypt them using [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html).

```
ansible-vault encrypt secret-vars.yml --vault-password-file ~/.vault_pass.txt
```

then in your playbook include the secret vars file.

```
- hosts: primary

  vars_files:
    - ./vars/secret-vars.yml
    - ./vars/vars.yml

  roles:
    - artifactory
```

## Bastion Hosts
In many cases, you may want to run this Ansible collection through a Bastion host to provision JFrog servers. You can include the following Var for a host or group of hosts:

```
ansible_ssh_common_args: '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -A user@host -W %h:%p"'

eg.
ansible_ssh_common_args: '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -A ubuntu@{{ azureDeployment.deployment.outputs.lbIp.value }} -W %h:%p"'
```