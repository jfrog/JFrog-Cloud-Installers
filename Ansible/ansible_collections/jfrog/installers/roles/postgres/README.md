# postgres
The postgres role will install Postgresql software and configure a database and user to support an Artifactory or Xray server.

### Role Variables
* _db_users_: This is a list of database users to create. eg. db_users: - { db_user: "artifactory", db_password: "Art1fAct0ry" }
* _dbs_: This is the database to create. eg. dbs: - { db_name: "artifactory", db_owner: "artifactory" }

## Example Playbook
```
---
- hosts: database
  roles:
    - postgres
```