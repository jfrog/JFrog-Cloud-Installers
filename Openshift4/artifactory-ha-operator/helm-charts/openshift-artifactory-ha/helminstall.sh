#!/usr/bin/env bash

if [[ -z "$1" ]]
then 
  echo "Skipping creation of persistent volume examples. Ensure there is available PVs 200Gi per node for HA." 
else
  oc new-project jfrog-artifactory
  oc create serviceaccount svcaccount -n jfrog-artifactory
  oc adm policy add-scc-to-user privileged system:serviceaccount:jfrog-artifactory:svcaccount
  oc adm policy add-scc-to-user anyuid system:serviceaccount:jfrog-artifactory:svcaccount
  oc adm policy add-scc-to-group anyuid system:authenticated

  # enables hostPath plugin for openshift system wide
  oc create -f hostpathscc.yaml -n jfrog-artifactory
  oc patch securitycontextconstraints.security.openshift.io/hostpath --type=merge --patch='{"allowHostDirVolumePlugin": true}'
  oc adm policy add-scc-to-user hostpath system:serviceaccount:jfrog-artifactory:svcaccount

  # create the license secret
  oc create secret generic artifactory-license --from-file=artifactory.cluster.license

  # create the tls secret
  oc create secret tls tls-ingress --cert=jfrog.team.crt --key=jfrog.team.key
fi  

# install via helm
helm install artifactory-ha . \
               --set artifactory-ha.nginx.tlsSecretName=tls-ingress \
               --set artifactory-ha.artifactory.license.secret=artifactory-license,artifactory-ha.artifactory.license.dataKey=artifactory.cluster.license
