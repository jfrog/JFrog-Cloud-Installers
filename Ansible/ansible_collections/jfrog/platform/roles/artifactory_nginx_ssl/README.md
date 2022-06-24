# artifactory_nginx_ssl
The artifactory_nginx_ssl role installs and configures nginx for SSL.

## Role Variables
* _server_name_: This is the server name. eg. "artifactory.54.175.51.178.xip.io"
* _certificate_: This is the SSL cert.
* _certificate_key_: This is the SSL private key.
* _nginx_worker_processes_: The worker_processes configuration for nginx. Defaults to 1.
* _artifactory_proxy_extra_config_: Enables adding extra options to the reverse proxy to artifactory.
* _replicator_enabled_: Whether or not to include the replicator location block. Defaults to `false`.
