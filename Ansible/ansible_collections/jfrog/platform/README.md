# JFrog Platform Ansible Collection

This Ansible directory consists of the following directories that support the JFrog Platform collection.

 * ansible_collections directory - This directory contains the Ansible collection package that has the Ansible roles for Artifactory, Distribution and Xray. See the roles README for details on the product roles and variables.
 * examples directory - This directory contains example playbooks for various architectures.


 ## Getting Started

 ## Prerequisites
From 10.11.x collection and above, Using fully qualified collection name (FQCN) , This is required for installing collection dependencies

```bash
ansible-galaxy collection install community.postgresql community.general ansible.posix
```

 1. Install this collection from Ansible Galaxy.

    ```
    ansible-galaxy collection install jfrog.platform
    ```

    Ensure you reference the collection in your playbook when using these roles.

    ```yaml
    ---
    - hosts: artifactory_servers
      collections:
        - jfrog.platform
        - community.general
      roles:
        - artifactory

    ```

 2. Ansible uses SSH to connect to hosts. Ensure that your SSH private key is on your client and the public keys are installed on your Ansible hosts.

 3. Create your inventory file. Use one of the examples from the examples directory to construct an inventory file (hosts.ini) with the host addresses

 4. Create your playbook. Use one of the examples from the examples directory to construct a playbook using the JFrog Ansible roles. These roles will be applied to your inventory and provision software.

 5. Then execute with the following command to provision the JFrog Platform with Ansible.

```bash
ansible-playbook -vv platform.yml -i hosts.ini
```

## Generating Master and Join Keys
**Note** : If you don't provide these keys, they will be set to defaults (check groupvars/all/vars.yaml file)
For production deployments,You may want to generate your master and join keys and apply it to all the nodes.
**IMPORTANT** : Save below generated master and join keys for future upgrades

```bash
MASTER_KEY_VALUE=$(openssl rand -hex 32)
JOIN_KEY_VALUE=$(openssl rand -hex 32)
ansible-playbook -vv platform.yml -i hosts.ini --extra-vars "master_key=$MASTER_KEY_VALUE join_key=$JOIN_KEY_VALUE"
```

## Using [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) to Encrypt Vars
Some vars you may want to keep secret. You may put these vars into a separate file and encrypt them using [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html).

For example, you will probably change the default password for the admin user using an encrypted file.

```yaml
# Default password
artifactory_admin_password: password
```


```bash
ansible-vault encrypt secret-vars.yml --vault-password-file ~/.vault_pass.txt
```

then in your playbook include the secret vars file.

```yaml
- hosts: artifactory_servers
  collections:
    - community.general
  vars_files:
    - ./vars/secret-vars.yml
    - ./vars/vars.yml

  roles:
    - artifactory
```

## Upgrades
All JFrog product roles support software updates. To use a role to perform a software update only, use the _<product>_upgrade_only_ variable and specify the version. See the following example.

```yaml
- hosts: artifactory_servers
  collections:
    - community.general
  vars:
    artifactory_version: "{{ lookup('env', 'artifactory_version_upgrade') }}"
    artifactory_upgrade_only: true
  roles:
    - artifactory

- hosts: xray_servers
  collections:
    - community.general
  vars:
    xray_version: "{{ lookup('env', 'xray_version_upgrade') }}"
    xray_upgrade_only: true
  roles:
    - xray
```

## Using External Database
If an external database for one or more products is to be used, you don't need to run `postgres` role as part of platform.yml.This can also be done by setting  `postgres_enabled` should be set to `false` in `group_vars/all/vars.yml`

Create an external database as documented [here](https://www.jfrog.com/confluence/display/JFROG/PostgreSQL#PostgreSQL-CreatingtheArtifactoryPostgreSQLDatabase) and change corresponding product values in `group_vars/all/vars.yml`

For example, for artifactory, these below values needs to be set for using external postgresql

```yaml
postgres_enabled: false

artifactory_db_type: postgresql
artifactory_db_driver: org.postgresql.Driver
artifactory_db_name: <external_db_name>
artifactory_db_user: <external_db_user>
artifactory_db_password: <external_db_pasword>
artifactory_db_url: jdbc:postgresql://<external_db_host_ip>:5432/{{ artifactory_db_name }}

```

## Building the Collection Archive
1. Go to the ansible_collections/jfrog/platform directory.
2. Update the galaxy.yml meta file as needed. Update the version.
3. Build the archive. (Requires Ansible 2.9+)
```bash
ansible-galaxy collection build
```

## OS support
The JFrog Platform Ansible Collection can be installed on the following operating systems:

* Ubuntu LTS versions (20.04/22.04)
* Centos/RHEL 8.x/9.x
* Debian 10.x/11.x
* Amazon Linux 2

## Note

* From 10.17.x platform collection, Artifactory (7.77.x) is not supported on Ubuntu - 18.04, Centos/RHEL - 7.x

* From 10.18.x platform collection , It is recommended to use Postgresql 15 for fresh installations , Change `postgres_version : 15` in postgres/defaults/vars.yaml

## How to avoid IPv6 binding

Some distributions have two entries for localhost in `/etc/hosts`:

```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
```

This can cause Java apps trying binding using IPv6, which fails when that's disabled. This causes some tcp ports not listening, like the Artifactory router service.

Solution: add an extra JAVA_OPTION: `-Djava.net.preferIPv4Stack=true` to this variable:

```
artifactory_extra_java_opts: '-server -Xms512m -Xmx4g -Xss256k -XX:+UseG1GC -Djava.net.preferIPv4Stack=true'
```

## Known issues
* Refer [here](https://github.com/jfrog/JFrog-Cloud-Installers/issues?q=is%3Aopen+is%3Aissue+label%3AAnsible)