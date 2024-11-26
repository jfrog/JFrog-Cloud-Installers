# artifactory_nginx_ssl
The artifactory_nginx_ssl role installs and configures nginx for SSL.

## Role Variables
* _server_name_: This is the server name. eg. "artifactory.54.175.51.178.xip.io"
* _ssl_certificate_install_: `true` - install the SSL certificate and private key. When `false` you need to manage certs yourself.  
* _ssl_certificate_: This is the filename of the SSL certificate.
* _ssl_certificate_path_: This is the full directory path for the SSL certificate, excluding _ssl_certificate_.
* _ssl_certificate_key_: This is the filename of the SSL private key.
* _ssl_certificate_key_path_: This is the full directory path for the SSL private key, excluding _ssl_certificate_key_.
* _nginx_worker_processes_: The worker_processes configuration for nginx. Defaults to 1.
* _artifactory_docker_registry_subdomain_: Whether to add a redirect directive to the nginx config for the use of docker
  subdomains.
* _mtls_ca_certificate_install_: `false` - Enable mTLS by updating to `true`
* _mtls_mtls_ca_certificate_crt_name_: This is the full name of the CA certificate
* _mtls_ca_certificate_path_: This is the full directory path for the CA certificate
* _mtls_mtls_ca_certificate_key_name_: This is the full name of the CA key
* _mtls_ca_certificate_crt_: This is the place to add the certificate
* _mtls_ca_certificate_key_: This is the place to add the key


# Configuring mTLS in Artifactory with NGINX
**To enable mTLS (Mutual TLS) authentication in Artifactory through NGINX, follow these steps:**

1. NGINX Changes
2. Artifactory Changes

## Step: 1 - NGINX Changes

Open `main.yml` in `artifactory_nginx_ssl` from the following location:

`platform/products/ansible/ansible_collections/jfrog/platform/roles/artifactory_nginx_ssl/defaults/main.yml`

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

In the same `main.yaml`, update the following flags to:

- `artifactory_nginx_ssl_enabled: true`
- `artifactory_nginx_enabled: false`

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


