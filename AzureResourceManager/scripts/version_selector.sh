#!/bin/bash
if [ $ARTIFACTORY_VERSION = 6.16.0 ] || [ $ARTIFACTORY_VERSION = 6.17.0 ] ; then
  sh install_artifactory.sh
else
  sh install_artifactory7.sh
fi