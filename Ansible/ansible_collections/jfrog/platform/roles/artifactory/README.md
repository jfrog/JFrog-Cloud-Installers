# artifactory
The artifactory role installs the Artifactory Pro software onto the host. Per the Vars below, it will configure a node as primary or secondary. This role uses secondary roles artifactory_nginx to install nginx.

## Role Variables

### Defaults variables

| Name                                      | Default Value                     | Description                                                                                            |
|-------------------------------------------|-----------------------------------|--------------------------------------------------------------------------------------------------------|
| `artifactory_server_name`                 | `inventory_hostname`              | **Mandatory.** The hostname used to access the Artifactory server. Adjust for production environments. |
| `artifactory_version`                     | `7.84.14`                         | The version of Artifactory to install.  |
| `artifactory_nginx_installed`             | `true`                            | Install and configure NGINX with Artifactory. Set to false if NGINX is not required. If true, see variables in table below.  |
| `artifactory_licenses`                    | `null`                            | Provide single or HA individual licenses file separated by new line and 2-space indentation.  |
| `artifactory_upgrade_only`                | `false`                           | If this is set, only perform an upgrade. |
| `artifactory_ha_enabled`                  | `false`                           | To enable High Availability (HA) mode, set to true. |
| `artifactory_taskaffinity`                | `any`                             | By default, all nodes are primary (CNHA). |
| `artifactory_mc_enabled`                  | `true`                            | To enable mission-control in Artifactory (applicable only on E+ license and for versions >= 7.27.x).  |
| `artifactory_jfrog_dir`                   | `/opt/jfrog`                      | Location where Artifactory should be installed. |
| `artifactory_dir`                         | `/opt/jfrog/artifactory`          | Dynamic - append `/artifactory` to the `artifactory_jfrog_dir` directory path.  |
| `artifactory_flavour`                     | `pro`                             | Pick the Artifactory flavor to install (e.g., cpp-ce/jcr/pro).  |
| `artifactory_extra_java_opts`             | `-server -Xms512m -Xmx4g -Xss256k -XX:+UseG1GC` | Additional Java options for Artifactory.  |
| `artifactory_download_timeout`            | `10`                              | Timeout in seconds for URL request. |
| `artifactory_postgresql_driver_download`  | `true`                            | Boolean, set to true to download JDBC driver. |
| `artifactory_postgresql_driver_version`   | `42.7.3`                          | Version of the PostgreSQL driver to download. |
| `artifactory_user`                        | `artifactory`                     | Default system user for Artifactory. |
| `artifactory_group`                       | `artifactory`                     | Default system group for Artifactory.  |
| `artifactory_uid`                         | `1030`                            | User ID for the Artifactory user.  |
| `artifactory_gid`                         | `1030`                            | Group ID for the Artifactory group.  |
| `artifactory_allow_non_postgresql`        | `false`                           | To run Artifactory with any database other than PostgreSQL, set to true. |
| `artifactory_allow_crontab`               | `true`                            | Allow the Artifactory user to create crontab rules for rotating console.log files.  |

**Additional variables for artifactory_nginx if artifactory_nginx_installed is true**

| Variable Name                                         | Default Value                           | Description |
|-------------------------------------------------------|-----------------------------------------|-------------|
| `artifactory_nginx_worker_processes`                  | `auto`                                  | Specifies the number of NGINX worker processes, Defaults to auto to match the number of CPU cores. |
| `artifactory_nginx_enable_docker_registry_rewrite`    | `false`                                 | If true, enables a rewrite rule for Docker registry requests in the NGINX configuration. |
| `artifactory_nginx_enable_ssl`                        | `false`                                 | Enables SSL configuration on NGINX. Important to secure connections. |
| `artifactory_nginx_enable_http_to_https_redirection`  | `false`                                 | Enables HTTP to HTTPS redirection; requires `nginx_enable_ssl` to be true. |
| `artifactory_nginx_ca_chain_name`                     | `ca_chain.pem`                          | File name of the CA chain. |
| `artifactory_nginx_ssl_certificate_name`              | `{{ inventory_hostname ~ '.crt.pem' }}` | File name of the SSL certificate. |
| `artifactory_nginx_ssl_private_key_name`              | `{{ inventory_hostname ~ '.key.pem' }}` | File name of the SSL private key. |
| `artifactory_nginx_ca_chain_content`                  | `''`                                    | Content of the CA Chain. Store this variable in a vault file using block scalar. |
| `artifactory_nginx_ssl_certificate_content`           | `''`                                    | Content of the Certificate. Store this variable in a vault file using block scalar. |
| `artifactory_nginx_ssl_private_key_content`           | `''`                                    | Content of the Private key. Store this variable in a vault file using block scalar. |
| `artifactory_nginx_use_official_repos`                | `false`                                 | Set to true to use NGINX's official repositories for package installations. |
| `artifactory_nginx_enabled_repositories`              | `[]`                                    | List of repositories to enable when installing NGINX. Only applicable for CentOS/RHEL. |
| `artifactory_nginx_disabled_repositories`             | `[]`                                    | List of repositories to disable when installing NGINX. Only applicable for CentOS/RHEL. |

## Example Playbook

```
---yaml
- hosts: artifactory_servers
  collections:
    - community.general
  roles:
    - artifactory
```

## Upgrades
The Artifactory role supports software upgrades. To use a role to perform a software upgrade only, use the _artifactory_upgrade_only_ variable and specify the version. See the following example.

```yaml
- hosts: artifactory_servers
  collections:
    - community.general
  vars:
    artifactory_version: "{{ lookup('env', 'artifactory_version_upgrade') }}"
    artifactory_upgrade_only: true
  roles:
    - artifactory
```
