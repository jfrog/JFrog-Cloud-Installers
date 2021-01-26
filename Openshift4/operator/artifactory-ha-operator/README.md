# JFrog Artifactory Enterprise Operator

This code base is intended to deploy Artifactory HA as an operator to an Openshift4 cluster. You can run the operator either through the operator-sdk, operator.yaml, or the Operatorhub.

Openshift OperatorHub has the latest official supported Cluster Service Version (CSV) for the OLM catalog.


## Security Context Constraints

To deploy this helm chart you will need to be a cluster admin w/ access to the anyuid scc.

````bash
oc adm policy add-scc-to-user anyuid -z artifactory-ha-operator -n namespace
````

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

## Prerequisites

###### Openshift 4 Cluster

Available on AWS, GCP, or Azure. Follow the Cloud installer guide available here:

[Openshift 4 Installers](https://cloud.redhat.com/openshift/install)

Or run it locally using CodeReadyContainers.

[Code Ready Container Installer](https://cloud.redhat.com/openshift/install/crc/installer-provisioned)

Note if you are going to use CodeReadyContainers to test this Operator you will need to ensure:

``` 
 - create at least one Persistent volume of 200Gi per Artifactory node used in HA configuration
```

###### Openshift 4 Command Line Tools

Download and install the Openshift command line tool: oc

[Getting Started with CLI](https://docs.openshift.com/container-platform/4.2/cli_reference/openshift_cli/getting-started-cli.html)

## Cluster Setup
###### Security Context Constraints - Anyuid

Openshift only allows statefulsets / pods to run in specific user and group id ranges.
Artifactory currently uses users outside of this allowed range.
For this reason the service account for the operator in the jfrog-artifactory namespace must be granted anyuid privileges.

```
oc adm policy add-scc-to-user anyuid system:serviceaccount:jfrog-artifactory:artifactory-ha-operator
```

Where anyuid is the Security context constraint being applied to the service account artifactory-ha-operator in namespace jfrog-artifactory.

In addition to this the restricted scc policy will need to be changed to allow anyuid:

``` 
oc patch scc restricted --patch '{"fsGroup":{"type":"RunAsAny"},"runAsUser":{"type":"RunAsAny"},"seLinuxContext":{"type":"RunAsAny"}}' --type=merge
```

The privileged scc policy will need to be changed to include the artifactory-ha-operator as an admin account:

```
oc patch scc privileged --patch  '{"users":["system:admin","system:serviceaccount:openshift-infra:build-controller","system:serviceaccount:jfrog-artifactory:artifactory-ha-operator"]}' --type=merge
```

###### Persistent Volumes on Code Ready Containers

Artifactory HA nodes by default request persistent volume claims 200 Gbs in size. 

If your cluster does not already have existing persistent volumes that are 200Gi you will need to create new persistent volumes that are large enough to bound the claims to.

## Installation types
###### OLM Catalog
To install via the OLM catalog download the operator from the Operator hub and install it via the Openshift console GUI

To test OLM catalog installs you will need to deploy the lastest ClusterServiceVersion found at:

```
deploy/olm-catalog/artifactory-ha-operator/X.X.X/artifactory-ha-operator.vX.X.X.clusterserviceversion.yaml
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

## Local Testing

Please refer to cluster setup. Ensure all steps have been completed prior to local testing against code ready containers.

Follow these steps:

Install code ready containers if you do not already have it installed.

Run your cluster with 2 cpus and 8192 MBs of memory at a minimum to support HA:

```
crc start -c 2 -m 8192
```

Recommended settings:

```
crc start -c 4 -m 16384
```

Create file: 

```
JFrog-Cloud-Installers/Openshift4/artifactory.cluster.license
```

Paste your license keys into this file for HA configuration of multiple nodes.

* License keys must be separated by two new lines.

Run: 

```
JFrog-Cloud-Installers/Openshift4/artifactory-ha-operator/setup.sh
```

###### Operator-sdk local

Run: 

```
cd JFrog-Cloud-Installers/Openshift4/artifactory-ha-operator
operator-sdk up local
```

## Contributing
Please read [CONTRIBUTING.md](JFrog-Cloud-Installers/Openshift4/artifactory-ha-operator/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning
We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/jfrog/JFrog-Cloud-Installers/tags).

## Contact

Github Issues
