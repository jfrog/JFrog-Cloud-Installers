# xray
The xray role will install Xray software onto the host. An Artifactory server and Postgress database is required.

### Role Variables
* _xray_version_: The version of Artifactory to install. eg. "3.3.0"
* _jfrog_url_: This is the URL to the Artifactory base URL. eg. "http://ec2-54-237-207-135.compute-1.amazonaws.com"
* _master_key_: This is the Artifactory [Master Key](https://www.jfrog.com/confluence/display/JFROG/Managing+Keys). See below to [autogenerate this key](#autogenerating-master-and-join-keys).
* _join_key_: This is the Artifactory [Join Key](https://www.jfrog.com/confluence/display/JFROG/Managing+Keys). See below to [autogenerate this key](#autogenerating-master-and-join-keys).
* _db_type_: This is the database type. eg. "postgresql"
* _db_driver_: This is the JDBC driver class. eg. "org.postgresql.Driver"
* _db_url_: This is the database url. eg. "postgres://10.0.0.59:5432/xraydb?sslmode=disable"
* _db_user_: The database user to configure. eg. "xray"
* _db_password_: The database password to configure. "xray"
* _xray_system_yaml_: Your own [system YAML](https://www.jfrog.com/confluence/display/JFROG/System+YAML+Configuration+File) file can be specified and used. If specified, this file will be used rather than constructing a file from the parameters above.
* _xray_upgrade_only_: Perform an software upgrade only. Default is false.

Additional variables can be found in [defaults/main.yml](./defaults/main.yml).
## Example Playbook
```
---
- hosts: xray
  roles:
    - xray
```

## Upgrades
The Xray role supports software upgrades. To use a role to perform a software upgrade only, use the _xray_upgrade_only_ variables and specify the version. See the following example.

```
- hosts: xray
  vars:
    xray_version: "{{ lookup('env', 'xray_version_upgrade') }}"
    xray_upgrade_only: true
  roles:
    - xray
```