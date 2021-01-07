# artifactory
The artifactory role installs the Artifactory Pro software onto the host. Per the Vars below, it will configure a node as primary or secondary. This role uses secondary roles artifactory_nginx to install nginx.

1.1.1 contains breaking changes. To mitigate this, use the role before doing any upgrades, let it mitigate the path changes, and then run again with your upgrade.

## Role Variables
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
* _artifactory_system_yaml_: Your own [system YAML](https://www.jfrog.com/confluence/display/JFROG/System+YAML+Configuration+File) file can be specified and used. **If specified, this file will be used rather than constructing a file from the parameters above.**
* _binary_store_file_: Your own [binary store file](https://www.jfrog.com/confluence/display/JFROG/Configuring+the+Filestore) can be used. If specified, the default cluster-file-system will not be used.
* _artifactory_upgrade_only_: Perform an software upgrade only. Default is false.

### primary vars (vars used by the primary Artifactory server)
* _artifactory_is_primary_: For the primary node this must be set to **true**.
* _artifactory_license1 - 5_: These are the cluster licenses.
* _artifactory_license_file_: Your own license file can be used. **If specified, a license file constructed from the licenses above will not be used.**

### secondary vars (vars used by the secondary Artifactory server)
* _artifactory_is_primary_: For the secondary node(s) this must be set to **false**.

### standalone vars (PRO or PRO X licenses)
* _artifactory_ha_enabled_: must be set to **false** 
* _artifactory_license1_: specify your PRO or PRO X license.

Additional variables can be found in [defaults/main.yml](./defaults/main.yml).

## Example Playbook
```
---
- hosts: primary
  roles:
    - artifactory
```

## Upgrades
The Artifactory role supports software upgrades. To use a role to perform a software upgrade only, use the _artifactory_upgrade_only_ variable and specify the version. See the following example.

```
- hosts: artifactory
  vars:
    artifactory_version: "{{ lookup('env', 'artifactory_version_upgrade') }}"
    artifactory_upgrade_only: true
  roles:
    - artifactory
```
