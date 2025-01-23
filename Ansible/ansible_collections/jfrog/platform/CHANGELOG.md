# JFrog Platform Ansible Collection Changelog
All changes to this collection will be documented in this file.

## [10.20.4] - January 07, 2025
* Product Updates/fixes

## [10.20.1] - Nov 26, 2024
* Postgres - Fixed auth method in pg_hba.conf file [GH-428](https://github.com/jfrog/JFrog-Cloud-Installers/pull/428)
* Artifactory - Fixed issue around /etc/cron.allow does not exist [GH-420](https://github.com/jfrog/JFrog-Cloud-Installers/issues/420)
* Xray - Added `centos_gpg_key` variable to override defaults [GH-420](https://github.com/jfrog/JFrog-Cloud-Installers/issues/413)
* Added support for RHEL 9
* Artifactory - Added AccessConfig Patch support to use mTLS [GH-392](https://github.com/jfrog/JFrog-Cloud-Installers/pull/392)
* Product Updates/fixes

## [10.20.0] - Oct 29, 2024
* Product Updates/fixes

## [10.19.7] - Oct 23, 2024
* Product Updates/fixes

## [10.19.6] - Oct 8, 2024
* Product Updates/fixes

## [10.19.5] - Sep 11, 2024
* Fixed Insight Password bug with system yaml override [GH-408](https://github.com/jfrog/JFrog-Cloud-Installers/issues/408)
* Product Updates/fixes

## [10.19.4] - Aug 28, 2024
* Product Updates/fixes

## [10.19.3] - Aug 16, 2024
* Product Updates/fixes

## [10.19.2] - Aug 9, 2024
* Product Updates/fixes

## [10.19.1] - Aug 6, 2024
* Product Updates/fixes

## [10.19.0] - Jul 25, 2024
* Product Updates/fixes

## [10.18.3] - Jul 15, 2024
* Product Updates/fixes

## [10.18.2] - June 12, 2024
* Distribution - Fixed redis directory permission bug for upgrades
* Product Updates/fixes

## [10.18.1] - May 26, 2024
* Product Updates/fixes

## [10.18.0] - May 12, 2024
* Product Updates/fixes
* Added a new variable `artifactory_allowNonPostgresql` (default false) in systemYaml to run Artifactory with any database other than PostgreSQL
* Xray - Support RHEL 9 in rabbitmq setup [GH-354](https://github.com/jfrog/JFrog-Cloud-Installers/pull/354)

## [10.17.4] - May 2, 2024
* Product Updates/fixes

## [10.17.3] - Mar 14, 2024
* Postgres - Added no_log to postgres username password assertion [GH-374](https://github.com/jfrog/JFrog-Cloud-Installers/pull/374)
* Product Updates/fixes

## [10.17.2] - March 7, 2024
* Fix - ansible.cfg issue


## [10.17.1] - Feb 29, 2024
* Artifactory - Upgrade fails during the Check artifactory version [GH-369](https://github.com/jfrog/JFrog-Cloud-Installers/pull/369)

## [10.17.0] - Jan 24, 2024
* **IMPORTANT**
* From 10.17.x platform collection, Artifactory (7.77.x) is not supported on Ubuntu 18.04, Centos/RHEL 7.x
* Product Updates/fixes

## [10.16.5] - Jan 05, 2024
* Postgres - change to the new location of the RPM GPG key URL. [GH-362](https://github.com/jfrog/JFrog-Cloud-Installers/pull/362)
* Product Updates/fixes

## [10.16.4] - Dec 21, 2023
* Artifactory - Upgrade version when tar is already present [GH-356](https://github.com/jfrog/JFrog-Cloud-Installers/pull/356)

## [10.16.3] - Dec 6, 2023
* Added How to avoid IPv6 binding in Readme [GH-349](https://github.com/jfrog/JFrog-Cloud-Installers/pull/349)
* Product Updates/fixes

## [10.16.2] - Nov 10, 2023
* Postgres - Change postgres_apt_repository_repo url for ubuntu 18
* Product Updates/fixes

## [10.16.1] - Nov 3, 2023
* Artifactory - Fix bootstrap template issue [GH-340](https://github.com/jfrog/JFrog-Cloud-Installers/pull/340)

## [10.16.0] - Oct 26, 2023
* Artifactory - Configure admin credentials [GH-335](https://github.com/jfrog/JFrog-Cloud-Installers/pull/335)
* Postgres - Assert that database username and password are defined [GH-336](https://github.com/jfrog/JFrog-Cloud-Installers/pull/336)
* Xray - Added a condition to check if socat already exists in rabbitmq
* Product Updates/fixes

## [10.15.3] - Oct 16, 2023
* Product Updates/fixes

## [10.15.2] - Sep 28, 2023
* Product Updates/fixes

## [10.15.0] - Sep 12, 2023
* Increase heap space in artifactory java opts [GH-329](https://github.com/jfrog/JFrog-Cloud-Installers/issues/329)
* Product Updates/fixes

## [10.14.8] - Aug 29, 2023
* Fixed - http to https redirect with nginx get double slash [GH-324](https://github.com/jfrog/JFrog-Cloud-Installers/issues/324)
* Product Updates/fixes

## [10.14.7] - Aug 18, 2023
* Fixed - artifactory role does not update java options during upgrade [GH-320](https://github.com/jfrog/JFrog-Cloud-Installers/issues/320)
* Product Updates/fixes

## [10.14.6] - Aug 10, 2023
* Product Updates/fixes

## [10.14.5] - Aug 4, 2023
* Product Updates/fixes

## [10.14.4] - Aug 2, 2023
* Product Updates/fixes

## [10.14.3] - Jul 20, 2023
* Added optional variable `download_postgres_driver` to skip driver download (defaults to true) for airgap environments [GH-315](https://github.com/jfrog/JFrog-Cloud-Installers/issues/315)

## [10.14.1] - Jul 14, 2023
* Fixed - Allow customizing binarystore.xml by adding `artifactory_binarystore` variable again [GH-313](https://github.com/jfrog/JFrog-Cloud-Installers/issues/313)

## [10.14.0] - Jul 12, 2023
* Fixed - artifactory role fails when run twice due to stopping artifactory service  [GH-307](https://github.com/jfrog/JFrog-Cloud-Installers/issues/307)
* Product Updates/fixes

## [10.13.3] - Jul 1, 2023
* Updated artifactory postgresql driver to `42.6.0`
* Fixed - File store always configured as HA, excessive logging on single instance [GH-305](https://github.com/jfrog/JFrog-Cloud-Installers/issues/305)
* Removed `artifactory_binarystore` variable and now configured via binarystore template by default
* Product Updates/fixes

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
