#!/usr/bin/env bash
oc project default
oc apply -f helm-charts/openshift-artifactory-ha/pv-examples
oc apply -f deploy/project.yaml
oc apply -f deploy/namespace.yaml
oc project jfrog-artifactory
oc apply -f deploy/imagestream-nginx.yaml
oc apply -f deploy/imagestream-pro.yaml
oc apply -f deploy/imagestream-operator.yaml
oc patch image.config.openshift.io/cluster --type=merge --patch='{"spec":{"registrySources":{"insecureRegistries":["default-route-openshift-image-registry.apps-crc.testing"]}}}'
oc apply -f deploy/role.yaml
oc apply -f deploy/role_binding.yaml
oc apply -f deploy/service_account.yaml
oc apply -f deploy/securitycontextconstraints.yaml
oc adm policy add-scc-to-user  scc-admin system:serviceaccount:jfrog-artifactory:artifactory-ha-operator
oc adm policy add-scc-to-user  scc-admin system:serviceaccount:jfrog-artifactory:default
oc adm policy add-scc-to-user  anyuid system:serviceaccount:jfrog-artifactory:artifactory-ha-operator
oc adm policy add-scc-to-user anyuid system:serviceaccount:jfrog-artifactory:default
oc adm policy add-scc-to-group anyuid system:authenticated
oc apply -f deploy/hostpathscc.yaml
oc patch securitycontextconstraints.security.openshift.io/hostpath --type=merge --patch='{"allowHostDirVolumePlugin": true}'
oc adm policy add-scc-to-user hostpath system:serviceaccount:jfrog-artifactory:artifactory-ha-operator
oc apply -f deploy/crds/charts.helm.k8s.io_openshiftartifactoryhas_crd.yaml
oc apply -f deploy/crds/charts.helm.k8s.io_v1alpha1_openshiftartifactoryha_cr.yaml
oc create secret generic artifactory-license --from-file=../artifactory.cluster.license
