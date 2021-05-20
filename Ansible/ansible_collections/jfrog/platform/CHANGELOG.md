# JFrog Platform Ansible Collection Changelog
All changes to this collection will be documented in this file.

## [7.8.7] - May 20, 2021
* Fixed broken variables in Ansible collection for Missioncontrol - [120](https://github.com/jfrog/JFrog-Cloud-Installer/issue/120)

## [7.8.6] - May 10, 2021
* Fixed broken URLs in ansible galaxy - [108](https://github.com/jfrog/JFrog-Cloud-Installers/issues/108)
* Added option to configure system.yaml (using `<product>_systemyaml` variable)  and binarystore.xml (using `artifactory_binarystore` variable)

## [7.8.5] - May 3, 2021
* Added new `jfrog.platform` collection with Artifactory, Distribution, Missioncontrol and Xray roles
* Published `jfrog.platform` galaxy [collection](https://galaxy.ansible.com/jfrog/platform) release
* Added new `groups_vars/all/package_version.yml` file to define product versions
* Added global support for masterKey and joinKey values in `groups_vars/all/vars.yml`
* **IMPORTANT**
* Previous 1.x.x jfrog.installer [deprecated collection](https://github.com/jfrog/JFrog-Cloud-Installers/tree/ansible-v1.1.2/Ansible/ansible_collections/jfrog/installers) 
