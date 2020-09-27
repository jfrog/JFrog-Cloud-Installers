# JFrog Unified Platform On Openshift 

This code base is intended to deploy JFrog Unified Platform products as either helm or an operator to an Openshift4 cluster. 

You can run the operator either through the operator-sdk, operator.yaml, or the OperatorHub OLM (CSV).

Openshift OperatorHub has the latest official supported version to deploy via the GUI.

Optionally you can deploy into Openshift4 as helm.

## Prerequisites

###### Openshift 4 Cluster

Available on AWS, GCP, or Azure. Follow the Cloud installer guide available here:

[Openshift 4 Installers](https://cloud.redhat.com/openshift/install)

Or run it locally using CodeReadyContainers or your own on-perm solution.

[Code Ready Container Installer](https://cloud.redhat.com/openshift/install/crc/installer-provisioned)

Note if you are going to use CRC / On-prem to run the Operators you will need to ensure:

``` 
 - create at least one Persistent volume of 200Gi per Artifactory node used in HA configuration
 - create at least 3 or more additional Persistent volumes 100Gi in size or more for Postgresql, Rabbitmq, and other components used.
```

###### Openshift 4 Command Line Tools

Download and install the Openshift command line tool: oc

[Getting Started with CLI](https://docs.openshift.com/container-platform/4.2/cli_reference/openshift_cli/getting-started-cli.html)

## Next Steps

To install JFrog Operators please use the web console's OperatorHub to install the official operators. This is the easiest way to install it. 

If you wish to install the operator(s) locally please refer to the instructions that can be found in the README under artifactory-ha-operator.

## Helm Deployments

The necessary helm fixes for it to work in Openshift have been patched for each product in the following subfolders:

Artifactory HA Helm Chart:
```
openshift-artifactory-ha
```

Xray Helm Chart:
``` 
openshift-xray
```

However to use helm you will need to apply RunAsAny shown below:

```
oc patch scc restricted --patch '{"fsGroup":{"type":"RunAsAny"},"runAsUser":{"type":"RunAsAny"},"seLinuxContext":{"type":"RunAsAny"}}' --type=merge
```

Once your cluster has been patched you can then deploy via helm using the openshift charts shown above.

## Contributing
Please read [CONTRIBUTING.md](JFrog-Cloud-Installers/Openshift4/artifactory-ha-operator/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning
We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/jfrog/JFrog-Cloud-Installers/tags).

## Contact

Github issues