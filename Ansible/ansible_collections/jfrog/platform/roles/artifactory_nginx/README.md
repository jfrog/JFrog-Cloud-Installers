# artifactory_nginx

This role installs NGINX for artifactory. This role is automatically called by the artifactory role and isn't intended to be used separately.

## Role Variables

| Variable Name                                | Description                                              | Mandatory | Default Value |  
|----------------------------------------------|----------------------------------------------------------|-----------|---------------|
| `server_name`                                | The server FQDN.                                         | Yes       | `inventory_hostname` |
| `artifactory_docker_registry_subdomain`      | Whether to add a redirect directive to the nginx config for the use of docker subdomains. | No | `false` |
| `artifactory_nginx_setup_repos`              | Setup offical repositories from Nginx.                     | No  | `false`       |
| `artifactory_nginx_ssl_enabled`              | Enable SSL for Nginx.                                      | No  | `false`       |
| `redirect_http_to_https_enabled`             | Enable redirect from HTTP to HTTPS.                        | No  | `true`        |
| `ssl_certificate_name`                       | The name of the SSL certificate file.                      | No  | `'cert.pem'`  |
| `ssl_certificate`                            | The SSL certificate content (Use text block `|`).          | No  | `''`          |
| `ssl_private_key_name`                       | The name of the SSL private key file.                      | No  | `'key.pem'`   |
| `ssl_private_key`                            | The SSL private key content. (Use text block `|`).         | No  | `''`          |
| `ca_certificate_chain_name`                  | The name of the CA certificate chain file.                 | No  | `'ca_certificate_chain.pem'`  |
| `ca_certificate_chain`                       | The CA certificate chain content (Use text block `|`).     | No  | `''`          |
