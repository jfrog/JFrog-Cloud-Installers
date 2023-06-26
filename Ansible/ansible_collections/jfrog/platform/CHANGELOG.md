# JFrog Platform Ansible Collection Changelog
All changes to this collection will be documented in this file.

## [10.13.3] - Jun 26, 2023
* Fixed binarystore.xml for single instance setup.

## [10.13.2] - Jun 21, 2023
* Added retry options for Postgresql download [GH-293](https://github.com/jfrog/JFrog-Cloud-Installers/issues/293)
* Fix the redirect on port 80 points to the default page for Nginx [GH-298](https://github.com/jfrog/JFrog-Cloud-Installers/issues/298)
* Product Updates/fixes

## [10.13.1] - Jun 6, 2023
* Fixed db-util / db5.3-util package installation on Ubuntu 20[GH-296](https://github.com/jfrog/JFrog-Cloud-Installers/issues/296)
* Product Updates/fixes

## [10.13.0] - Jun 2, 2023
* Added support for  Ubuntu 22 and Debain 11
* Product Updates/fixes

## [10.12.3] - May 22, 2023
* Allow using crontab [GH-276](https://github.com/jfrog/JFrog-Cloud-Installers/pull/276/files)
* Allow using external TLS certificates [GH-278](https://github.com/jfrog/JFrog-Cloud-Installers/pull/278)
* Allow changing of postgres_data_dir [GH-279](https://github.com/jfrog/JFrog-Cloud-Installers/pull/279/files)
* Intermediate TLS configuration [GH-280](https://github.com/jfrog/JFrog-Cloud-Installers/pull/280/files)
* Fixed SELinux context on bin directory [GH-282](https://github.com/jfrog/JFrog-Cloud-Installers/pull/282/files)
* Fixed flag handler to be boolean [GH-286](https://github.com/jfrog/JFrog-Cloud-Installers/pull/286/files)
* Product Updates/fixes

## [10.12.2] - May 2, 2023
* Product Updates/fixes

## [10.12.1] - Mar 27, 2023
* Conditionally start Xray service [GH-275](https://github.com/jfrog/JFrog-Cloud-Installers/pull/275)
* Set SELinux boolean httpd_can_network_connect [GH-271](https://github.com/jfrog/JFrog-Cloud-Installers/pull/271)
* Fix file permission of Nginx TLS key [GH-269](https://github.com/jfrog/JFrog-Cloud-Installers/pull/269)
* Adding variables for certificate and key paths [GH-267](https://github.com/jfrog/JFrog-Cloud-Installers/pull/267)
* Fix code-style [GH-265](https://github.com/jfrog/JFrog-Cloud-Installers/pull/265)
* Product Updates/fixes

## [10.12.0] - Mar 1, 2023
* Conditionally start Artifactory service [GH-260](https://github.com/jfrog/JFrog-Cloud-Installers/pull/260)
* Allow overriding nginx config templates [GH-261](https://github.com/jfrog/JFrog-Cloud-Installers/pull/261)
* Updated artifactory postgresql driver to `42.5.4`
* Product Updates/fixes

## [10.11.6] - Feb 27, 2023
* Product Updates/fixes

## [10.11.5] - Feb 16, 2023
* Product Updates/fixes

## [10.11.4] - Feb 7, 2023
* Product Updates/fixes

## [10.11.3] - Jan 30, 2023
* **IMPORTANT**
* Refactored code to support fully qualified collection name (FQCN), Please refer [here](https://github.com/jfrog/JFrog-Cloud-Installers/blob/master/Ansible/ansible_collections/jfrog/platform/README.md#getting-started#prerequisites)
* Fixed - Artifactory installService.sh script will never be launched during an upgrade [GH-251](https://github.com/jfrog/JFrog-Cloud-Installers/issues/251)
* Updated RedHat Nginx installer tasks to use HTTPS URLs [GH-253](https://github.com/jfrog/JFrog-Cloud-Installers/pull/253)
* Fixed - Upgrade play to stop artifactoy service [GH-255](https://github.com/jfrog/JFrog-Cloud-Installers/pull/255)
* Improved offline upgrades [GH-257](https://github.com/jfrog/JFrog-Cloud-Installers/pull/257)
* Updated artifactory postgresql driver to `42.5.1`

## [10.10.2] - Dec 22, 2022
* Product Updates/fixes

## [10.10.1] - Dec 13, 2022
* Product Updates/fixes

## [10.10.0] - Dec 7, 2022
* Product Updates/fixes

## [10.9.4] - Nov 11, 2022
* Removed support for Debian 9
* Product Updates/fixes

## [10.9.3] - Oct 31, 2022
* Product Updates/fixes

## [10.9.2] - Oct 27, 2022
* Product Updates/fixes
* Fixed Typo in ansible collection: amd -> and [GH-244](https://github.com/jfrog/JFrog-Cloud-Installers/pull/244)

## [10.9.1] - Oct 14, 2022
* Product Updates/fixes

## [10.9.0] - Oct 11, 2022
* Product Updates/fixes
* Fixed strange permissions for TLS directories [GH-193](https://github.com/jfrog/JFrog-Cloud-Installers/issues/193)
* Added support for Docker registries via subdomain [GH-136](https://github.com/jfrog/JFrog-Cloud-Installers/issues/136)
* Added Amazon Linux 2 compatibility [GH-231](https://github.com/jfrog/JFrog-Cloud-Installers/pull/231)
* Added installService.sh for upgrading Artifactory [GH-238](https://github.com/jfrog/JFrog-Cloud-Installers/pull/238)

## [10.8.6] - Oct 4, 2022
* Product Updates/fixes

## [10.8.5] - Sep 21, 2022
* Product Updates/fixes

## [10.8.4] - Sep 5, 2022
* Product Updates/fixes

## [10.8.3] - Aug 18, 2022
* Product Updates/fixes

## [10.8.2] - Aug 10, 2022
* Product Updates/fixes

## [10.8.1] - Aug 3, 2022
* Product Updates/fixes

## [10.8.0] - July 12, 2022
* Product Updates/fixes

## [10.7.0] - June 21, 2022
* Updated artifactory postgresql driver to `42.3.6`
* Product Updates/fixes

## [10.6.2] - May 20, 2022
* Allow nginx configuration for overriding worker_processes with a variable [GH-217](https://github.com/jfrog/JFrog-Cloud-Installers/pull/217)
* Product Updates/fixes

## [10.6.1] - May 16, 2022
* Product Updates/fixes

## [10.6.0] - May 10, 2022
* Keep SELinux settings on upgrade + check mode [GH-214](https://github.com/jfrog/JFrog-Cloud-Installers/pull/214)
* Artifactory - Add support for default database driver [GH-213](https://github.com/jfrog/JFrog-Cloud-Installers/pull/213)
* Product Updates/fixes

## [10.5.2] - Apr 27, 2022
* Product Updates/fixes

## [10.5.1] - Apr 18, 2022
* Product Updates/fixes

## [10.5.0] - Apr 14, 2022
* Product Updates/fixes

## [10.4.1] - Mar 22, 2022
* Product Updates/fixes

## [10.4.0] - Mar 9, 2022
* Removed suport for ubuntu 16 LTS version
* Product Updates/fixes

## [10.3.2] - Feb 18, 2022
* Product Updates/fixes

## [10.3.1] - Feb 17, 2022
* Product Updates/fixes

## [10.3.0] - Feb 8, 2022
* Performance improvement for permission check [GH-192](https://github.com/jfrog/JFrog-Cloud-Installers/pull/192)
* Fixed - Artifactory upgrade mode breaks existing installation [GH-194](https://github.com/jfrog/JFrog-Cloud-Installers/issues/194)
* Product Updates/fixes

## [10.2.0] - Jan 31, 2022
* Product Updates/fixes

## [10.1.2] - Dec 23, 2021
* Product Updates/fixes

## [10.1.1] - Dec 17, 2021
* Product Updates/fixes

## [10.1.0] - Dec 7, 2021
* Updated artifactory postgresql driver to `42.3.1`
* Update nginx installation on RHEL8/CentOS8 [GH-175](https://github.com/jfrog/JFrog-Cloud-Installers/pull/175)
* Fixed idempotency issue when FIPS is enabled on the target [GH-176](https://github.com/jfrog/JFrog-Cloud-Installers/pull/176)

## [10.0.4] - Nov 30, 2021
* Product fixes

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
