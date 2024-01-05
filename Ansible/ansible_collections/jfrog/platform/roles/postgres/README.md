# postgres
The postgres role will install Postgresql software and configure a database and user to support an Artifactory or Xray server.

### Role Variables

By default, the [_pg_hba.conf_](https://www.postgresql.org/docs/13/auth-pg-hba-conf.html) client authentication file is configured for open access for development purposes through the _postgres_allowed_hosts_ variable:

```
postgres_allowed_hosts:
  - { type: "host", database: "all", user: "all", address: "0.0.0.0/0", method: "trust"}
```

**THIS SHOULD NOT BE USED FOR PRODUCTION.**

**Update this variable to only allow access from Artifactory, Distribution, Insight and Xray.**


Since 2024-01-03 the GPG key has a new location.
```
postgres_rpmkey_url: "https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-RHEL"
```
## Example Playbook
```
---
- hosts: postgres_servers
  collections:
    - community.postgresql
    - community.general
  roles:
    - postgres
```
