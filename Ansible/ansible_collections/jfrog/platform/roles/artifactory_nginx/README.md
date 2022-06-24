# artifactory_nginx
This role installs NGINX for artifactory. This role is automatically called by the artifactory role and isn't intended to be used separately.

## Role Variables
* _server_name_: **mandatory** This is the server name. eg. "artifactory.54.175.51.178.xip.io"
* _nginx_worker_processes_: The worker_processes configuration for nginx. Defaults to 1.
* _artifactory_proxy_extra_config_: Enables adding extra options to the reverse proxy to artifactory.
* _replicator_enabled_: Whether or not to include the replicator location block. Defaults to `false`.
