# JFrog Pipeline Enterprise Operator

This code base is intended to deploy Pipelines as an operator to an Openshift4 cluster. 
Openshift OperatorHub has the latest official supported Cluster Service Version (CSV) for the OLM catalog.

## Prerequisites

###### Openshift 4 Cluster

Available on AWS, GCP, or Azure. Follow the Cloud installer guide available here:

[Openshift 4 Installers](https://cloud.redhat.com/openshift/install)

###### Openshift 4 Command Line Tools

Download and install the Openshift command line tool: oc

[Getting Started with CLI](https://docs.openshift.com/container-platform/4.2/cli_reference/openshift_cli/getting-started-cli.html)

## Cluster Setup
###### Security Context Constraints - Anyuid

Openshift only allows statefulsets / pods to run in specific user and group id ranges.
Pipelines currently uses users outside of this allowed range since some containers must run as root.
Depending upon your namespace you must be granted anyuid privileges to the pipeline-operator service account.

```
oc adm policy add-scc-to-user anyuid -z pipeline-operator
```

## Contributing
Please read [CONTRIBUTING.md](JFrog-Cloud-Installers/Openshift4/xray-operator/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning
We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/jfrog/JFrog-Cloud-Installers/tags).

## Contact

Github Issues