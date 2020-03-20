#!/usr/bin/env bash
oc project jfrog-artifactory
oc delete deployments --all
oc delete statefulsets --all
oc delete configmaps --all
oc delete deploymentconfigs --all
oc delete pods --all
oc delete svc --all
oc delete networkpolicies --all
oc delete pvc --all
oc delete PodDisruptionBudget --all
for s in $(oc get secrets | grep artifactory | cut -f1 -d ' '); do
    oc delete secret $s
done
oc delete serviceaccount artifactoryha-artifactory-ha
oc delete role artifactoryha-artifactory-ha  
