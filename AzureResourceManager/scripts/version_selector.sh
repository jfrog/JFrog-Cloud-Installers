#!/bin/bash
if [ $ARTIFACTORY_VERSION = 6.16.0 ] || [ $ARTIFACTORY_VERSION = 6.17.0 ] ; then
  sh scripts/install_artifactory.sh
else
  sh scripts/install_artifactory7.sh
fi