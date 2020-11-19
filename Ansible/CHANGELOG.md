# Changelog

All notable changes to this project will be documented in this file.

## [] - 2020-11-19
- Updated example hosts file to be explicit about pulling passwords,keys from env vars.

## [1.1.2] - 2020-10-29
- Updated default versions to RT 7.10.2 and Xray 3.10.3.
- Removed obsolete gradle tests.

## [1.1.1] - 2020-10-15
- added idempotence to artifactory installer
- added fix for derby deployments
- Migration to reduce changes during playbook runs contains breaking changes. You either must run once before upgrade, or provide playbook with valid credentials to access version information for it to perform properly.
- First time installers need not worry about above

## [1.1.0] - 2020-09-27

- Validated for Artifactory 7.7.8 and Xray 3.8.6.
- Added offline support for Artifactory and Xray.
- Added support for configurable Postgres pg_hba.conf.
- Misc fixes due to Artifactory 7.7.8.
- Published 1.1.0 to [Ansible Galaxy](https://galaxy.ansible.com/jfrog/installers).
