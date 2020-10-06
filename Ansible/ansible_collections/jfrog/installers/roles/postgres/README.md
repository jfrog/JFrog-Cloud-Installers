# postgres
The postgres role will install Postgresql software and configure a database and user to support an Artifactory or Xray server.

### Role Variables
* _db_users_: This is a list of database users to create. eg. db_users: - { db_user: "artifactory", db_password: "Art1fAct0ry" }
* _dbs_: This is the database to create. eg. dbs: - { db_name: "artifactory", db_owner: "artifactory" }

By default, the [_pg_hba.conf_](https://www.postgresql.org/docs/9.1/auth-pg-hba-conf.html) client authentication file is configured for open access for development purposes through the _postgres_allowed_hosts_ variable:

```
postgres_allowed_hosts:
  - { type: "host", database: "all", user: "all", address: "0.0.0.0/0", method: "trust"}
```

**THIS SHOULD NOT BE USED FOR PRODUCTION.**

**Update this variable to only allow access from Artifactory and Xray.**

## Example Playbook
```
---
- hosts: database
  roles:
    - postgres
```