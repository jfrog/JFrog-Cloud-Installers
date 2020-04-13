#!/usr/bin/env bash

if [[ -z "$1" ]]
then 
  echo "Skipping creation of persistent volume examples. Ensure there is available PVs 200Gi per node for HA." 
else
  # patch the restricted scc to allow the pods to run as anyuid
  oc patch scc restricted --patch '{"fsGroup":{"type":"RunAsAny"},"runAsUser":{"type":"RunAsAny"},"seLinuxContext":{"type":"RunAsAny"}}' --type=merge

  # create the license secret
  oc create secret generic artifactory-license --from-file=artifactory.cluster.license

  # create the tls secret
  oc create secret tls tls-ingress --cert=tls.crt --key=tls.key
fi  

# install via helm
helm install artifactory-ha . \
               --set artifactory-ha.nginx.tlsSecretName=tls-ingress \
               --set artifactory-ha.artifactory.license.secret=artifactory-license,artifactory-ha.artifactory.license.dataKey=artifactory.cluster.license
