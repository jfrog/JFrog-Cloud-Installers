#!/bin/bash
ARTIFACTORY_VERSION=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_VERSION=" | sed "s/ARTIFACTORY_VERSION=//")
IFS=$'\t'
SUPPORTED_VERSIONS=("6.8.0\t6.11.3\t6.15.0\t0.16.0\t0.17.0\t6.18.0")
unset IFS

if [[ "\t${SUPPORTED_VERSIONS[@]}\t" =~ "\t${ARTIFACTORY_VERSION}\t" ]]; then
      sh install_artifactory.sh
      echo "\ninstall_artifactory.sh was selected" >> user-data.txt
else
	    sh install_artifactory7.sh
      echo "\ninstall_artifactory7.sh was selected" >> user-data.txt
fi