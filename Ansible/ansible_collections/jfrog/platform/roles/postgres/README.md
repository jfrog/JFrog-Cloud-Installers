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

| Database Attribute        | Example Values                                                                       | Description                                            |
|---------------------------|--------------------------------------------------------------------------------------|--------------------------------------------------------|
| `name`                    | `{{ artifactory_db_name | d('artifactory') }}`, `{{ xray_db_name | d('xray') }}`, etc.| Name of the database configured dynamically.          |
| `username`                | `{{ artifactory_db_user_name | d('artifactory') }}`, etc.                            | Username for the database.                             |
| `userpass`                | `{{ artifactory_db_user_pass | d('...') }}`                                          | Password for the database user.                        |
| `userpass_encrypted`      | `{{ artifactory_db_user_pass_encrypted | d('true') }}`                               | Indicates if the password is encrypted.                |
| `userprivs`               | `{{ artifactory_db_user_privs | d(['ALL']) }}`                                       | Privileges for the user.                               |
| `owner`                   | `{{ artifactory_db_owner | d(...) }}`                                                | Owner of the database. (default is artifactory_db_user_name)|
| `lc_collate`, `lc_ctype`  | Locale settings derived from `postgresql_locale`.                                    | Locale settings for collation and character type.      |
| `encoding`                | `{{ artifactory_db_encoding | d('UTF-8') }}`                                         | Encoding for the database.                             |
| `template`                | `{{ artifactory_db_template | d('template0') }}`                                     | Template used to create the database.                  |
| `login_host`              | `{{ artifactory_db_login_host | d('localhost') }}`                                   | Host for logging into the database.                    |
| `login_port`              | `{{ artifactory_db_login_port | d(null) }}`                                          | Port for logging into the database.                    |
| `login_user`              | `{{ artifactory_db_login_user | d(postgresql_user) }}`                               | User for logging into the database.                    |
| `login_password`          | `{{ artifactory_db_login_password | d(null) }}`                                      | Password for logging into the database.                |
| `login_unix_socket`       | `{{ artifactory_db_unix_socket | d(null) }}`                                         | Unix socket for logging into the database.             |
| `state`                   | `{{ artifactory_db_state | d(...) }}`                                                | State of the database (present, absent).               |
| `driver`                  | `{{ artifactory_db_driver | d('org.postgresql.Driver') }}`                           | Database driver.                                       |
| `url`                     | Dynamically generated JDBC connection strings.                                       | URL for database connections.                          |

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
