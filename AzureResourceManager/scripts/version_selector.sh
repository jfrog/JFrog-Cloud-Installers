#!/bin/bash
ARTIFACTORY_VERSION=$(cat /var/lib/cloud/instance/user-data.txt | grep "^ARTIFACTORY_VERSION=" | sed "s/ARTIFACTORY_VERSION=//")
if [ "$ARTIFACTORY_VERSION" = 6.16.0 ] || [ "$ARTIFACTORY_VERSION" = 6.17.0 ] || [ "$ARTIFACTORY_VERSION" = 0.16.0 ];
then
  sh install_artifactory.sh
  echo "\ninstall_artifactory.sh was selected" >> user-data.txt
else
  sh install_artifactory7.sh
  echo "\ninstall_artifactory7.sh was selected" >> user-data.txt
fi