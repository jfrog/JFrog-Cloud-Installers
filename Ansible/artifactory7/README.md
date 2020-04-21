# rt7ansible
This repo contains the Ansible collection for JFrog Artifactory Pro 7 roles. These roles allow you to provision Artifactory for High-Availability using a Primary node and multiple Secondary nodes. Additionally, a Postgresql role is provided for installing an Artifactory Postgresql database.

## Roles Provided
### artifactory
The artifactory role installs the Artifactory Pro software onto the host. Per the Vars below, it will configure a node as primary or secondary.

### artifactory-postgres
The artifactory-postgres role will install Postgresql software and configure an artifactory database and user.

### artifactory-java
The artifactory-java role ensures that the correct version of Java is installed for Artifactory.

## Vars Required
The following Vars must be configured.

### all
* ansible_user: The SSH user to access the hosts. eg. "ubuntu"
* ansible_ssh_private_key_file: The SSH key to use. eg. "/Users/jefff/.ssh/jeff-ec2-us-east.pem"
* db_user: The Artifactory database user to configure. eg. "artifactory"
* db_password: The Artifactory database password to configure. "Art1fact0ry"
* server_name: This is the LB DNS or IP. eg. "ansibleelb-623062857.us-east-1.elb.amazonaws.com"
* certificate: This is the SSL cert.
* certificate_key: This is the SSL private key.

### artifactory
* master_key: This is the Artifactory Master Key.
* join_key: This is the Artifactory Join Key.
* db_download_url: This is the download URL for the JDBC driver for your database. eg. "https://jdbc.postgresql.org/download/postgresql-42.2.12.jar"
* db_type: This is the database type. eg. "postgresql"
* db_driver: This is the JDBC driver class. eg. "org.postgresql.Driver"
* db_url: This is the JDBC database url. eg. "jdbc:postgresql://10.0.0.120:5432/artifactory"

### primary
* artifactory_is_primary: For the primary node this must be set to **true**.
* artifactory_license1 - 5: These are the cluster licenses.

### secondary
* artifactory_is_primary: For the secondary node(s) this must be set to **false**.

### Example Inventory YAML
An example inventory YAM is [here](hosts.yml).

### Example Playbook
An playbook is [here](rt7provision.yml).

## Executing a Playbook
```
ansible-playbook -i hosts.yml rt7provision.yml
```
