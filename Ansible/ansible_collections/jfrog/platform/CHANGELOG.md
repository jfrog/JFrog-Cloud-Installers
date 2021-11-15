# JFrog Platform Ansible Collection Changelog
All changes to this collection will be documented in this file.

## [10.0.3] - Nov 15, 2021
* Product fixes

## [10.0.2] - Oct 29, 2021
* Product fixes

## [10.0.1] - Oct 22, 2021
* Version bump to align with all jfrog platform installers
* Added insight (new product) role
* Missioncontrol (`artifactory_mc_enabled: true`) is now part of artifactory (>= 7.27.x) - [Migrating from Missioncontrol to Insight for existing installations](https://www.jfrog.com/confluence/display/JFROG/Migrating+from+Mission+Control+to+Insight)
* Removed `artifactory_single_license` variable,From artifactory version >=7.27.6,`artifactory_licenses` can be used for both single/HA modes
* Added SELinux support for RHEL systems [GH-161](https://github.com/jfrog/JFrog-Cloud-Installers/pull/161)
* Added rolling upgrade support for artifactory HA installations(using `serial` approach)
* Updated artifactory postgresql driver to `42.2.24`

## [7.25.7] - Sep 16, 2021
* Bug Fixes

## [7.24.3] - Aug 17, 2021 
* Added required variables check when using `artifactory_nginx_ssl` role
* Missioncontrol's Elasticsearch to use default ES JAVA_HOME
* Bug Fixes

## [7.23.4] - Aug 9, 2021
* Missioncontrol's Elasticsearch to use default ES JAVA_HOME

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
