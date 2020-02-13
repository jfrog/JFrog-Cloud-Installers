# Openshift 4 Artifactory Operator
## Cluster Setup
###### Security Context Constraints - Anyuid + Hostpath
###### Persistent Volumes
###### 
## Installation types
###### OLM Catalog
To install via the OLM catalog download the operator from the Operator hub and install it via the Openshift console GUI

To test OLM catalog installs you will need to deploy the lastest ClusterServiceVersion found at:
 deploy/olm-catalog/artifactory-ha-operator/X.X.X/artifactory-ha-operator.vX.X.X.clusterserviceversion.yaml

This will install the operator into whatever cluster your kubectl or oc program is currently logged into.

Please refer to Local Testing section below for full instructions.

###### Operator YAML
To install the operator via the Operator YAML first follow the steps in 


###### Operator-sdk local

 

## Local Testing

