Artifactory Master
=========

A configuration for Artifactory through Cloud Formation. This assumes it will be tied to an AutoScale group, the
environment will have 2 boot groups. 1 with `art_primary=True` and the other `art_primary=False`. Note: The MasterKey
must match in both boot groups or they will not connect.

Requirements
------------

This role is dependent on specific inputs, but does not require any other roles.

Role Variables
--------------

artifactory_licesnes is expected as a list of Artifactory licesnse.
artifactory_server_name is the DNS name of the Artifactory instance.
certificate_domain: Domain name for the DNS name of the Artifactory instance.
s3_endpoint: S3 URL endpoint for backend storage.
s3_access_key: S3 Access key for the S3 Endpoint + Bucket.
s3_access_secret_key: S3 Secret key for the S3 Endpoint + Bucket.
s3_bucket: S3 bucket for backend storage.
certificate_key: Private Certificate Key used for NGINX to terminate SSL
certificate: Certificate used by NGINX to terminate SSL
db_type: Currently only MySQL is supported.
db_ipaddr: MySQL endpoint for the DB connection.
db_name: Name of the Database.
db_user: User with write/read permission on the `db_name`
db_password: Password for the `db_user`
art_primary: True or False (Very important that only one node is art_primary=True)
artifactory_keystore_pass: Java Keystore new Password
master_key: Master Cluster key to join the Artifactory cluster.
artifactory_version: Version of Artifactory to install.

Dependencies
------------

None

Example Playbook
----------------

```yaml
- import_playbook: site-artifactory.yml
  vars:
    artifactory_licenses: ${ArtifactoryLicense}
    artifactory_server_name: ${ArtifactoryServerName}
    certificate_domain: ${CertificateDomain}
    s3_endpoint: s3.${AWS::Region}.amazonaws.com
    s3_access_key: ${ArtifactoryIAMAcessKey}
    s3_access_secret_key: ${SecretAccessKey}
    s3_bucket: ${ArtifactoryS3Bucket}
    certificate_key: ${CertificateKey}
    certificate: ${Certificate}
    db_type: ${DBType}
    db_ipaddr: ${ArtifactoryDBEndpointAddress}
    db_name: ${DatabaseName}
    db_user: ${DatabaseUser}
    db_password: ${DatabasePassword}
    art_primary: ${ArtifactoryPrimary}
    artifactory_keystore_pass: ${KeystorePassword}
    master_key: ${MasterKey}
    artifactory_version: ${ArtifactoryVersion}
```

License
-------

BSD

Author Information
------------------
