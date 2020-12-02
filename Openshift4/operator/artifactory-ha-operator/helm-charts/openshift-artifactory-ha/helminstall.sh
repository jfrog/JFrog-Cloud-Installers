#!/usr/bin/env bash

# PreReq'd:
# helm install postgres bitnami/postgresql
# follow artifactory postgresql db setup:
# https://www.jfrog.com/confluence/display/JFROG/PostgreSQL
NAMESPACE="default"
POSTGRES=$(helm ls -n $NAMESPACE | grep postgres | wc -l)

if [[ "$POSTGRES" =~ (0) ]]
then
  echo "External DB is required to run Jfrog Openshift Artifactory Helm chart"
  echo ""
  echo "Postgresql helm chart must be installed prior to installing this helm installer script."
  echo ""
  echo "helm install postgres bitnami/postgresql"
  echo ""
  echo "follow artifactory postgresql db setup:"
  echo "https://www.jfrog.com/confluence/display/JFROG/PostgreSQL"
  exit 1
else
  if [[ -z "$1" ]]
  then
    echo "Installing Jfrog Artifactory Openshift Helm"
  else
    echo "Patching Environment for RunAsAnyUid"
    # patch the restricted scc to allow the pods to run as anyuid
    oc patch scc restricted --patch '{"fsGroup":{"type":"RunAsAny"},"runAsUser":{"type":"RunAsAny"},"seLinuxContext":{"type":"RunAsAny"}}' --type=merge
    if [[ -f "artifactory.cluster.license" ]]
    then
      echo "Creating k8s secret for Artifactory cluster licenses from file: artifactory.cluster.license"
      # create the license secret
      oc create secret generic artifactory-license --from-file=artifactory.cluster.license
    fi
    
    if [[ -f "tls.crt" ]]
    then
      echo "Creating k8s secret for TLS tls-ingress from files tls.crt & tls.key"
      # create the tls secret
      oc create secret tls tls-ingress --cert=tls.crt --key=tls.key
    fi
  fi
fi

MASTER_KEY=$(openssl rand -hex 32)
JOIN_KEY=$(openssl rand -hex 32)

# install via helm with default postgresql configuration
helm install artifactory-ha . \
               --set artifactory-ha.nginx.service.ssloffload=true \
               --set artifactory-ha.nginx.tlsSecretName=tls-ingress \
               --set artifactory-ha.artifactory.node.replicaCount=1 \
               --set artifactory-ha.artifactory.license.secret=artifactory-license,artifactory-ha.artifactory.license.dataKey=artifactory.cluster.license \
               --set artifactory-ha.database.type=postgresql \
               --set artifactory-ha.database.driver=org.postgresql.Driver \
               --set artifactory-ha.database.url=jdbc:postgresql://postgres-postgresql:5432/artifactory \
               --set artifactory-ha.database.user=artifactory \
               --set artifactory-ha.database.password=password \
               --set artifactory-ha.artifactory.joinKey=$JOIN_KEY \
               --set artifactory-ha.artifactory.masterKey=$MASTER_KEY


echo "*** IMPORTANT ****"
echo "export MASTER_KEY=$MASTER_KEY"
echo "export JOIN_KEY=$JOIN_KEY"
echo "*** SUCCESS ****"
