#!/usr/bin/env bash

# PreReq'd:
# helm install postgres bitnami/postgresql
# follow artifactory postgresql db setup:
# https://www.jfrog.com/confluence/display/JFROG/PostgreSQL
POSTGRES=$(helm ls | grep postgres | wc -l)
ARTIFACTORY=$(helm ls | grep artifactory | wc -l)
if [[ "$POSTGRES" =~ (0) ]]
then
  echo "External DB is required to run Jfrog Openshift Xray Helm chart"
  echo ""
  echo "Postgresql helm chart must be installed prior to installing this helm installer script."
  echo ""
  echo "helm install postgres bitnami/postgresql"
  echo ""
  echo "follow artifactory postgresql db setup:"
  echo "https://www.jfrog.com/confluence/display/JFROG/PostgreSQL"
  exit 1
elif [[ "$ARTIFACTORY" =~ (0) ]]
then
  echo "Artifactory Instance is required to run Jfrog Openshift Xray Helm chart"
  echo ""
  echo "Please use helm to first install Artifactory: openshift-artifactory-ha"
  echo ""
  echo "Then install Openshift xray helm chart once artifactory is ready."
  echo ""
  exit 1
else
  echo "Installing Openshift Xray Helm"
fi

DBURL=""
if [[ -z "$1" ]]
then
  DBURL="postgres://postgres-postgresql:5432/xraydb?sslmode=disable"
else
  DBURL=$1
fi

DBUSER=""
if [[ -z "$2" ]]
then
  DBUSER="artifactory"
else
  DBUSER=$2
fi

DBPASS=""
if [[ -z "$3" ]]
then
  DBPASS="password"
else
  DBPASS=$3
fi

JFROGURL=""
if [[ -z "$4" ]]
then
  JFROGURL="http://artifactory-ha-nginx"
else
  JFROGURL=$4
fi


# install via helm with default postgresql configuration
helm install xray . \
               --set xray.database.url=$DBURL \
               --set xray.database.user=$DBUSER \
               --set xray.database.password=$DBPASS \
               --set xray.xray.jfrogUrl=$JFROGURL
