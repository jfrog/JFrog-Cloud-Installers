#!/usr/bin/env bash

export stack_name=$1
export cfn_template="~/git/JFrog-Cloud-Installers/Ansible/infra/aws/lb-rt-xray-ha-ubuntu16.json"
export ssh_public_key_name=jeff-ansible
export artifactory_license_file="~/Desktop/artifactory.cluster.license"
export master_key=d8c19a03036f83ea45f2c658e22fdd60
export join_key=d8c19a03036f83ea45f2c658e22fdd61
export ansible_user=ubuntu
export artifactory_version="7.4.3"
export xray_version="3.4.0"
export artifactory_version_upgrade="7.6.1"
export xray_version_upgrade="3.5.2"
ansible-playbook Ansible/test/aws/playbook-ha-upgrade.yaml