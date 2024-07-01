# artifactory_nginx

This role installs NGINX for artifactory and is invoked by the artifactory role; it should not be used independently.

## Role Variables

### Defaults variables

| Variable Name                                  | Default Value                           | Description |
|------------------------------------------------|-----------------------------------------|-------------|
| `artifactory_nginx_server_name`                | `inventory_hostname`                    | Mandatory. The hostname used to access the Artifactory server. Adjust for production environments. |
| `artifactory_nginx_worker_processes`           | `auto`                                  | Specifies the number of NGINX worker processes, Defaults to auto to match the number of CPU cores. |
| `artifactory_nginx_enable_docker_registry_rewrite` | `false`                             | If true, enables a rewrite rule for Docker registry requests in the NGINX configuration. |
| `artifactory_nginx_enable_ssl`                | `false`                                  | Enables SSL configuration on NGINX. Important to secure connections. |
| `artifactory_nginx_enable_http_to_https_redirection` | `false`                           | Enables HTTP to HTTPS redirection; requires `nginx_enable_ssl` to be true. |
| `artifactory_nginx_ca_chain_name`                   | `ca_chain.pem`                           | File name of the CA chain. |
| `artifactory_nginx_ssl_certificate_name`            | `{{ inventory_hostname ~ '.crt.pem' }}`  | File name of the SSL certificate. |
| `artifactory_nginx_ssl_private_key_name`            | `{{ inventory_hostname ~ '.key.pem' }}`  | File name of the SSL private key. |
| `artifactory_nginx_ca_chain_content`                | `''`                                     | Content of the CA Chain. Store this variable in a vault file using block scalar. |
| `artifactory_nginx_ssl_certificate_content`         | `''`                                     | Content of the Certificate. Store this variable in a vault file using block scalar. |
| `artifactory_nginx_ssl_private_key_content`         | `''`                                     | Content of the Private key. Store this variable in a vault file using block scalar. |
| `artifactory_nginx_use_official_repos`        | `false`                                  | Set to true to use NGINX's official repositories for package installations. |
| `artifactory_nginx_enabled_repositories`      | `[]`                                     | List of repositories to enable when installing NGINX. Only applicable for CentOS/RHEL. |
| `artifactory_nginx_disabled_repositories`     | `[]`                                     | List of repositories to disable when installing NGINX. Only applicable for CentOS/RHEL. |


### Distribution variables

The following variables are distribution-specfic and should not be overriden.

| Variable Name                                  | Description                                                              |
|------------------------------------------------|--------------------------------------------------------------------------|
| `artifactory_nginx_official_repo_mapping`      | NGINX Repository - Mapps the repo names with ansible distribution names. |
| `artifactory_nginx_official_repo_filename`     | NGINX Repository - File name of the repository.                          |
| `artifactory_nginx_official_repo_description`  | NGINX Repository - Description of the repository.                        |
| `artifactory_nginx_official_repo_signing_key`  | NGINX Repository - URL of the signing key.                               |
| `artifactory_nginx_official_repo_url`          | NGINX Repository - URL of the repository.                                |
| `artifactory_nginx_os_packages`                | OS - List of the nginx packages to install.                              |
| `artifactory_nginx_os_daemon`                  | OS - Name of the nginx daemon.                                           |
| `artifactory_nginx_os_cmd_truststore_update`   | OS - Command to update the system trust-store.                           |
| `artifactory_nginx_os_dir_truststore`          | OS - Dictionary for the system trust-store directory.                    |
| `artifactory_nginx_os_dir_certs`               | OS - Dictionary for the system certificates directory.                   |
| `artifactory_nginx_os_dir_ssl`                 | OS - Dictionary for the system SSL directory.                            |
| `artifactory_nginx_os_dir_jfrog_ssl`           | OS - Dictionary for the JFROG SSL directory (?).                         |
| `artifactory_nginx_tpl_nginx_config`           | OS - Dictionary for the NGINX config template.                           |
| `artifactory_nginx_tpl_https_redirect`         | OS - Dictionary for the NGINX HTTP to HTTPS redirect config template.    |
| `artifactory_nginx_tpl_artifactory_config`     | OS - Dictionary for the NGINX Artifactory config template.               |
