# JFrog Platform Ansible Collection Changelog
All changes to this collection will be documented in this file.

## [7.9.4] - May 31, 2021
* Moved product versions from `groups_vars/all/package_version.yml` to roles/<product>/defaults
* Added variable to configure postgres apt key (`postgres_apt_key_url`) and id (`postgres_apt_key_id`)
* Squashed bugs from previous release

## [7.8.6] - May 10, 2021
* Fixed broken URLs in ansible galaxy - [108](https://github.com/jfrog/JFrog-Cloud-Installers/issues/108)
* Added variable to configure system.yaml (using `<product>_systemyaml`)  and binarystore.xml (using `artifactory_binarystore`)

## [7.8.5] - May 3, 2021
* Added new `jfrog.platform` collection with Artifactory, Distribution, Missioncontrol and Xray roles
* Published `jfrog.platform` galaxy [collection](https://galaxy.ansible.com/jfrog/platform) release
* Added new `groups_vars/all/package_version.yml` file to define product versions
* Added global support for masterKey and joinKey values in `groups_vars/all/vars.yml`
* **IMPORTANT**
* Previous 1.x.x jfrog.installer [deprecated collection](https://github.com/jfrog/JFrog-Cloud-Installers/tree/ansible-v1.1.2/Ansible/ansible_collections/jfrog/installers) 
