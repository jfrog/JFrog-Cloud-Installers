# artifactory_nginx

This role installs NGINX for artifactory. This role is automatically called by the artifactory role and isn't intended to be used separately.

## Role Variables

* _server_name_: **mandatory** This is the server name. eg. "artifactory.54.175.51.178.xip.io"
* _artifactory_docker_registry_subdomain_: Whether to add a redirect directive to the nginx config for the use of docker subdomains.