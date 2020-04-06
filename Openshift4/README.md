# JFrog Artifactory Enterprise Operator

This code base is intended to deploy Artifactory Enterprise (HA) as an operator to an Openshift4 cluster. 

You can run the operator either through the operator-sdk, operator.yaml, or the OperatorHub OLM (CSV).

Openshift OperatorHub has the latest official supported Cluster Service Version (CSV) for the OLM catalog.

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

## Next Steps

To install JFrog Artifactory Enterprise as an Openshift 4 operator please use the console's OperatorHub to install the official operator. This is the easiest way to install it. 

If you wish to install the operator locally please refer to the instructions that can be found in the README under artifactory-ha-operator.

## Contributing
Please read [CONTRIBUTING.md](JFrog-Cloud-Installers/Openshift4/artifactory-ha-operator/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning
We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/jfrog/JFrog-Cloud-Installers/tags).

## Contact

Github issues