# JFrog Xray Enterprise Operator

This code base is intended to deploy Xray as an operator to an Openshift4 cluster. You can run the operator either through the operator-sdk, operator.yaml, or the Operatorhub.

Openshift OperatorHub has the latest official supported Cluster Service Version (CSV) for the OLM catalog.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

## Prerequisites

###### Openshift 4 Cluster

Available on AWS, GCP, or Azure. Follow the Cloud installer guide available here:

[Openshift 4 Installers](https://cloud.redhat.com/openshift/install)

Or run it locally using CodeReadyContainers.

[Code Ready Container Installer](https://cloud.redhat.com/openshift/install/crc/installer-provisioned)

###### Openshift 4 Command Line Tools

Download and install the Openshift command line tool: oc

[Getting Started with CLI](https://docs.openshift.com/container-platform/4.2/cli_reference/openshift_cli/getting-started-cli.html)

## Cluster Setup
###### Security Context Constraints - Anyuid

Openshift only allows statefulsets / pods to run in specific user and group id ranges.
Xray currently uses users outside of this allowed range.
For this reason the service account for the operator in the jfrog-artifactory namespace must be granted anyuid privileges.

```
oc adm policy add-scc-to-user anyuid system:serviceaccount:jfrog-artifactory:xray-operator
```

Where anyuid is the Security context constraint being applied to the service account artifactory-ha-operator in namespace jfrog-artifactory.

In addition to this the restricted scc policy will need to be changed to allow anyuid:

``` 
oc patch scc restricted --patch '{"fsGroup":{"type":"RunAsAny"},"runAsUser":{"type":"RunAsAny"},"seLinuxContext":{"type":"RunAsAny"}}' --type=merge
```

## Installation types
###### OLM Catalog
To install via the OLM catalog download the operator from the Operator hub and install it via the Openshift console GUI

To test OLM catalog installs you will need to deploy the lastest ClusterServiceVersion found at:

```
deploy/olm-catalog/artifactory-ha-operator/X.X.X/xray-operator.vX.X.X.clusterserviceversion.yaml
```

This will install the operator into whatever cluster your kubectl or oc program is currently logged into.

Please refer to Local Testing section below for full instructions.

###### Operator YAML
To install the operator via the Operator YAML follow the Local Testing tests.

Instead of running operator-sdk up local for the last step run:

```
oc apply -f deploy/operator.yaml
```

This will deploy the operator into the cluster.

###### Operator-sdk local

Run: 

```
cd JFrog-Cloud-Installers/Openshift4/xray-operator
operator-sdk up local
```

## Contributing
Please read [CONTRIBUTING.md](JFrog-Cloud-Installers/Openshift4/xray-operator/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning
We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/jfrog/JFrog-Cloud-Installers/tags).

## Contact

Github Issues