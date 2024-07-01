# postgres
The postgres role will install Postgresql software and configure a database and user to support an Artifactory or Xray server.

### Role Variables

### Default variables

#### General 

| Name                              | Default Value                | Description                                                                 |
|-----------------------------------|------------------------------|-----------------------------------------------------------------------------|
| `postgresql_version`              | `13`                         | Version of PostgreSQL to install.                                           |
| `postgresql_use_official_repos`   | `false`                      | Set to true to use PostgreSQL's official repositories.                      |
| `postgresql_user`                 | `postgres`                   | Default PostgreSQL user.                                                    |
| `postgresql_group`                | `postgres`                   | Default PostgreSQL group.                                                   |
| `postgresql_auth_method`          | `scram-sha-256`              | Password authentication method, either `md5` or `scram-sha-256`.            |
| `postgresql_locale`               | `en_US.UTF-8`                | Locale setting for PostgreSQL databases.                                    |
| `postgresql_add_logrotate`        | `false`                      | Set to true to add logrotate configuration. (applies only if an asbsolute path is specified for log_directory)  |

#### Host Based Authentication (HBA) Configuration

Defaults to PostgreSQL default -- allowing only localhost:

| Type  | Database | User    | Address       | Auth Method                                |
|-------|----------|---------|---------------|--------------------------------------------|
| local | all      | postgres| -             | peer                                       |
| local | all      | all     | -             | peer                                       |
| host  | all      | all     | '127.0.0.1/32'| `{{ postgresql_auth_method }}`             |
| host  | all      | all     | '::1/128'     | `{{ postgresql_auth_method }}`             |

Note: For development purposes you may overide it with the following variable:

**THIS SHOULD NOT BE USED FOR PRODUCTION.**  
**Update this variable to only allow access from Artifactory, Distribution, Insight and Xray.**  

```yaml
postgres_allowed_hosts:
  - { type: "host", database: "all", user: "all", address: "0.0.0.0/0", method: "trust"}
```

** To dynamically add the HBA entries for the hosts in the inventory file set the following variable to true:**
`postgresql_hba_add_inventory_hosts: false`

#### Custom PostgreSQL Configuration Options

Customize PostreSQL by passing a list of dictionaries as option/value, example:

```yaml
postgresql_custom_config_options:
  - option: 'logging_collector'
    value: 'on'
  - option: 'log_directory'
    value: '/var/log/postgresql'
```

#### PostgreSQL Users and Databases Configuration

| Variable                               | Default Value                        | Description                                      |
|----------------------------------------|--------------------------------------|--------------------------------------------------|
| `artifactory_enabled`                  | true                                 | Creates Artifactory database                     |
| `artifactory_db_name`                  | artifactory                          | Name of the Artifactory database                 |
| `artifactory_db_user`                  | artifactory                          | User for the Artifactory database                |
| `artifactory_db_password`              | password                             | Password for the Artifactory database            |
| `artifactory_db_password_encrypted`    | true                                 | If Artifactory db password is encrypted          |
| `artifactory_db_user_privs`            | ['ALL']                              | Privileges for the Artifactory db user           |
| `artifactory_db_owner`                 | artifactory                          | Owner of the Artifactory database                |
| `artifactory_db_lc_collate`            | 'en_US.UTF-8'                        | Locale for collation in Artifactory db           |
| `artifactory_db_lc_ctype`              | 'en_US.UTF-8'                        | Locale for character classification in Artifactory db|
| `artifactory_db_encoding`              | 'UTF-8'                              | Encoding for the Artifactory database            |
| `artifactory_db_template`              | template0                            | Template for the Artifactory database creation   |
| `artifactory_db_login_host`            | ''                                   | Host for the Artifactory db connection           |
| `artifactory_db_login_port`            | ''                                   | Port for the Artifactory db connection           |
| `artifactory_db_login_user`            | ''                                   | User for the Artifactory db connection           |
| `artifactory_db_login_password`        | ''                                   | Password for the Artifactory db connection       |
| `artifactory_db_unix_socket`           | ''                                   | Unix socket for the Artifactory db connection    |
| `artifactory_db_state`                 | dynamic - based on artifactory_enabled  | State of the Artifactory database (present or absent) |
| `xray_enabled`                         | true                                 | Creates Xray database                            |
| `xray_db_name`                         | xray                                 | Name of the Xray database                        |
| `xray_db_user`                         | xray                                 | User for the Xray database                       |
| `xray_db_password`                     | password                             | Password for the Xray database                   |
| `xray_db_password_encrypted`           | true                                 | If Xray db password is encrypted                 |
| `xray_db_user_privs`                   | ['ALL']                              | Privileges for the Xray db user                  |
| `xray_db_owner`                        | xray                                 | Owner of the Xray database                       |
| `xray_db_lc_collate`                   | 'en_US.UTF-8'                        | Locale for collation in Xray db                  |
| `xray_db_lc_ctype`                     | 'en_US.UTF-8'                        | Locale for character classification in Xray db   |
| `xray_db_encoding`                     | 'UTF-8'                              | Encoding for the Xray database                   |
| `xray_db_template`                     | template0                            | Template for the Xray database creation          |
| `xray_db_login_host`                   | ''                                   | Host for the Xray db connection                  |
| `xray_db_login_port`                   | ''                                   | Port for the Xray db connection                  |
| `xray_db_login_user`                   | ''                                   | User for the Xray db connection                  |
| `xray_db_login_password`               | ''                                   | Password for the Xray db connection              |
| `xray_db_unix_socket`                  | ''                                   | Unix socket for the Xray db connection           |
| `xray_db_state`                        | dynamic - based on xray_enabled      | State of the Xray database (present or absent)   |
| `distribution_enabled`                 | true                                 | Creates Distribution database                    |
| `distribution_db_name`                 | distribution                         | Name of the Distribution database                |
| `distribution_db_user`                 | distribution                         | User for the Distribution database               |
| `distribution_db_password`             | password                             | Password for the Distribution database           |
| `distribution_db_password_encrypted`   | true                                 | If Distribution db password is encrypted         |
| `distribution_db_user_privs`           | ['ALL']                              | Privileges for the Distribution db user          |
| `distribution_db_owner`                | distribution                         | Owner of the Distribution database               |
| `distribution_db_lc_collate`           | 'en_US.UTF-8'                        | Locale for collation in Distribution db          |
| `distribution_db_lc_ctype`             | 'en_US.UTF-8'                        | Locale for character classification in Distribution db |
| `distribution_db_encoding`             | 'UTF-8'                              | Encoding for the Distribution database           |
| `distribution_db_template`             | template0                            | Template for the Distribution database creation  |
| `distribution_db_login_host`           | ''                                   | Host for the Distribution db connection          |
| `distribution_db_login_port`           | ''                                   | Port for the Distribution db connection          |
| `distribution_db_login_user`           | ''                                   | User for the Distribution db connection          |
| `distribution_db_login_password`       | ''                                   | Password for the Distribution db connection      |
| `distribution_db_unix_socket`          | ''                                   | Unix socket for the Distribution db connection   |
| `distribution_db_state`                | dynamic - based on insight_enabled   | State of the Distribution database (present or absent) |
| `insight_enabled`                      | true                                 | Creates Insight database                         |
| `insight_db_name`                      | insight                              | Name of the Insight database                     |
| `insight_db_user`                      | insight                              | User for the Insight database                    |
| `insight_db_password`                  | password                             | Password for the Insight database                |
| `insight_db_password_encrypted`        | true                                 | If Insight db password is encrypted              |
| `insight_db_user_privs`                | ['ALL']                              | Privileges for the Insight db user               |
| `insight_db_owner`                     | insight                              | Owner of the Insight database                    |
| `insight_db_lc_collate`                | 'en_US.UTF-8'                        | Locale for collation in Insight db               |
| `insight_db_lc_ctype`                  | 'en_US.UTF-8'                        | Locale for character classification in Insight db|
| `insight_db_encoding`                  | 'UTF-8'                              | Encoding for the Insight database                |
| `insight_db_template`                  | template0                            | Template for the Insight database creation       |
| `insight_db_login_host`                | ''                                   | Host for the Insight db connection               |
| `insight_db_login_port`                | ''                                   | Port for the Insight db connection               |
| `insight_db_login_user`                | ''                                   | User for the Insight db connection               |
| `insight_db_login_password`            | ''                                   | Password for the Insight db connection           |
| `insight_db_unix_socket`               | ''                                   | Unix socket for the Insight db connection        |
| `insight_db_state`                     | dynamic - based on insight_enabled   | State of the Insight database (present or absent)|

## Example Playbook

```yaml
---
- hosts: postgres_servers
  collections:
    - community.postgresql
    - community.general
  roles:
    - postgres
```
