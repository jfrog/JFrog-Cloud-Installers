# artifactory_nginx
The artifactory_nginx role installs and Optionally configures nginx for SSL.

## Role Variables
* _server_name_: This is the server name. eg. "artifactory.54.175.51.178.xip.io"

* _nginx_upstream_: `true` to enable usage of the official NGINX upstream repository. If `false`, NGINX must be managed separately or via OS repos.
* _nginx_upstream_repo_key_: URL to the NGINX GPG signing key. Default: `https://nginx.org/keys/nginx_signing.key`
* _nginx_upstream_repo_baseurl_: Base URL of the NGINX upstream repo.  
  - Use `https://nginx.org/packages/mainline` for **development/mainline** releases.  
  - Use `https://nginx.org/packages` for **stable** releases.

* _ssl_certificate_install_: `true` - install the SSL certificate and private key. When `false` you need to manage certs yourself.  
* _ssl_certificate_name_: This is the filename of the SSL certificate.
* _ssl_certificate_path_: This is the full directory path for the SSL certificate.
* _ssl_certificate_: This is the place to add the actual content of the SSL certificate.
* _ssl_certificate_key_name_: This is the filename of the SSL private key.
* _ssl_certificate_key_path_: This is the full directory path for the SSL private key.
* _ssl_certificate_key_: This is the place to add the actual content of the SSL private key.

* _nginx_module_: Specifies the version of the NGINX module to be used. Example: `'1.24'`.
* _redirect_http_to_https_enabled_: `true` to automatically redirect all HTTP traffic to HTTPS.
* _nginx_worker_processes_: The worker_processes configuration for nginx. Defaults to 1.
* _artifactory_docker_registry_subdomain_: Whether to add a redirect directive to the nginx config for the use of docker
  subdomains.

* _mtls_ca_certificate_install_: `false` - Enable mTLS by updating to `true`
* _mtls_mtls_ca_certificate_crt_name_: This is the filename of the CA certificate for mTLS
* _mtls_ca_certificate_path_: This is the full directory path for the CA certificate
* _mtls_mtls_ca_certificate_key_name_: This is the filename of the CA private key.
* _mtls_ca_certificate_crt_: This is the place to add the content of the CA certificate.
* _mtls_ca_certificate_key_: This is the place to add the content of CA private key. 

# Adding SSL certificates in Artifactory with NGINX
**To add SSL certificates in Artifactory through NGINX, follow these steps:**

1. Set the below variable in artifactory role
```
artifactory_nginx_ssl_enabled: true
```
2. Run the following command to create SSL certificates
```
openssl req -new -x509 -nodes -days 365 -subj '/CN=my-ca' -keyout ssl_certificate_key -out ssl_certificate
```
Add the `ssl_certificate` and `ssl_certificate_key` files to the relevant YAML file in the same directory.
Update the above generated certificates with below parameters:

ssl_certificate: | 

ssl_certificate_key: |


# Configuring mTLS in Artifactory with NGINX
**To enable mTLS (Mutual TLS) authentication in Artifactory through NGINX, follow these steps:**

1. NGINX Changes
2. Artifactory Changes

## Step: 1 - NGINX Changes

Open `main.yml` in `artifactory_nginx` from the following location:

`platform/products/ansible/ansible_collections/jfrog/platform/roles/artifactory_nginx/defaults/main.yml`

### Set Up CA Certificate

Modify the `mtls_ca_certificate_install` parameter from `false` to `true`.

**Create CA Certificates**: CA certificates in mTLS verifies the authenticity and trustworthiness of client and server certificates, ensuring secure and mutual authentication.

**Run the following command to create CA certificates:**

```
openssl req -new -x509 -nodes -days 365 -subj '/CN=my-ca' -keyout ca.key -out ca.crt
```

Add the `ca.crt` and `ca.key` files to the relevant YAML file in the same directory.
Update the above generated certificates with below parameters:

mtls_ca_certificate_crt: | 

mtls_ca_certificate_key: |


## Step: 2 - Arifactory Changes

### Enable mTLS Configuration
Under `artifactory_access_config_patch`, add the configuration in the following location to enable mTLS:
`platform/products/ansible/ansible_collections/jfrog/platform/roles/artifactory/defaults/main.yml`

```
security:
  authentication:
    mtls:
      enabled: true                  
      extraction-regex: (.*)
```

In the same `main.yaml`, update the following flag to:

- `artifactory_nginx_ssl_enabled: true`

For more information, refer to the [Artifactory Documentation](https://jfrog.com/help/r/jfrog-artifactory-documentation/set-up-mtls-verification-and-certificate-termination-on-the-reverse-proxy).

## Client Validation

**Follow the below steps to validate client:**

1. **Generate Server Certificate and Key for client validation**

Create the Server Key and Certificate:
Use the CA certificates created in [Step 1](#step-1---nginx-changes) to generate the server key and certificate.

```
openssl genrsa -out server.key 2048
```

```
openssl req -new -key server.key -subj '/CN=localhost' -out server.csr
```

```
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 365 -out server.crt
```

2. **Verify mTLS Configuration for client testing**
To test the mTLS setup, use a tool like curl:

```
curl -u <username>:<password> "http://<artifactory-url>/artifactory/api/system/ping" --cert server.crt --key server.key -k
```

This command should establish a connection using the configured mTLS, ensuring proper communication with Artifactory.

