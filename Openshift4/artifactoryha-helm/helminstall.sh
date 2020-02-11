#!/usr/bin/env bash

if [ -z "$1" ]; then echo "Skipping creation of persistent volume examples. Ensure there is available PVs 200Gi per node for HA."; else oc create -f pv-examples/; fi  

oc new-project jfrog-artifactory
oc create serviceaccount svcaccount -n jfrog-artifactory
oc adm policy add-scc-to-user privileged system:serviceaccount:jfrog-artifactory:svcaccount
oc adm policy add-scc-to-user anyuid system:serviceaccount:jfrog-artifactory:svcaccount
oc adm policy add-scc-to-group anyuid system:authenticated

# enables hostPath plugin for openshift system wide
oc create -f scc.yaml -n jfrog-artifactory
oc patch securitycontextconstraints.security.openshift.io/hostpath --type=merge --patch='{"allowHostDirVolumePlugin": true}' 
oc adm policy add-scc-to-user hostpath system:serviceaccount:jfrog-artifactory:svcaccount

# create the license secret
oc create secret generic artifactory-license --from-file=./artifactory.cluster.license

# install via helm
helm install . --generate-name \
               --set artifactory.node.replicaCount=1 \
               --set nginx.service.type=NodePort \
               --set artifactory.license.secret=artifactory-license,artifactory.license.dataKey=artifactory.cluster.license
