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
