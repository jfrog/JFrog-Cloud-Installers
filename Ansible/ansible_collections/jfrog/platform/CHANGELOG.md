# JFrog Platform Ansible Collection Changelog
All changes to this collection will be documented in this file.

## [7.23.3] - Aug 5, 2021
* Missioncontrol's Elasticsearch to use new JAVA_HOME path
* Missioncontrol's Elasticsearch searchguard plugin to use by default `anonymous_auth_enabled: true`

## [7.21.12] - July 30, 2021
* Added variable `postgres_enabled` to enable/disable default postgres role in `groups_vars/all/vars.yml`
* Added documentation to used external database
* Added support to override default systemyaml using `<product>_systemyaml_override`

## [7.21.7] - July 16, 2021
* Added variable to enable/disable each product in `groups_vars/all/vars.yml`
* Added variable download Timeout in seconds for URL request
* Updated artifactory postgresql driver to `42.2.23`

## [7.19.8] - June 9, 2021
* Fix Missioncontrol ES start issue

## [7.19.4] - May 31, 2021
* Moved product versions from `groups_vars/all/package_version.yml` to roles/<product>/defaults
* Added variable to configure postgres apt key (`postgres_apt_key_url`) and id (`postgres_apt_key_id`)
* Squashed bugs from previous release

## [7.18.6] - May 10, 2021
* Fixed broken URLs in ansible galaxy - [108](https://github.com/jfrog/JFrog-Cloud-Installers/issues/108)
* Added variable to configure system.yaml (using `<product>_systemyaml`)  and binarystore.xml (using `artifactory_binarystore`)

## [7.18.5] - May 3, 2021
* Added new `jfrog.platform` collection with Artifactory, Distribution, Missioncontrol and Xray roles
* Published `jfrog.platform` galaxy [collection](https://galaxy.ansible.com/jfrog/platform) release
* Added new `groups_vars/all/package_version.yml` file to define product versions
* Added global support for masterKey and joinKey values in `groups_vars/all/vars.yml`
* **IMPORTANT**
* Previous 1.x.x jfrog.installer [deprecated collection](https://github.com/jfrog/JFrog-Cloud-Installers/tree/ansible-v1.1.2/Ansible/ansible_collections/jfrog/installers) 
