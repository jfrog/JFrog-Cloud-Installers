# Setup JFrog Container Registry

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FJFrogDev%2FJFrog-Cloud-Installers%2Farm-jcr-non-ha%2FAzureResourceManager%2FmainTemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FJFrogDev%2FJFrog-Cloud-Installers%2Farm-jcr-non-ha%2FAzureResourceManager%2FmainTemplate.json" target="_blank">
<img src="http://armviz.io/visualizebutton.png"/>
</a>

This template can help you setup the [JFrog Container Registry](https://www.jfrog.com/confluence/display/JCR/Welcome+to+JFrog+Container+Registry) on Azure.

## A. Deploy JFrog Container Registry on Azure

1. Click the "Deploy to Azure" button.

2. Fill out the settings. Make sure to provide a valid SSL certificate. If using no certificate or one that is self-signed, see [Docker's documentation on client configuration](https://docs.docker.com/registry/insecure/).

3. Click on "Purchase" to start deploying resources. It will deploy:
    * Microsoft SQL database
    * Azure Blob storage service
    * A VM with NGINX and JFrog Container Registry
    * Azure Load Balancer

4. Once deployment is done. Copy FQDN from Output of deployment template.

5. Access artifactory using FQDN. 

### Note: 
1. Turn off daily backups.  Read Documentation provided [here](https://www.jfrog.com/confluence/display/RTF/Managing+Backups)
2. Add an SSL Certificate to access Docker without using the insecure option
3. Input values for 'adminUsername' and 'adminPassword' parameters needs to follow azure VM access rules.
4. Refer to [System Requirements](https://www.jfrog.com/confluence/display/RTF/System+Requirements) for changing 'extraJavaOptions' input parameter value. 

### Steps to setup Artifactory as secure docker registry
You will need a valid SSL certificate for a domain name (for example, artifactory.jfrog.team)
1. Pass your SSL Certificate in parameter `Certificate` as string
2. Pass your SSL Certificate Key in parameter `CertificateKey` as string
3. Create DNS record with an entry that matches your domain name pointing to the load balancer value provided as output in template deployment.
4. You should now be able to access any docker registry using the path method.
    * Login: `docker login  [domain name]` in our example, that would be `docker login artifactory.jfrog.team`
    * Pull/Push to a particular repository: `docker pull [domain name]/[repository name]/[image name]:[tag]`
        * Example with our domain, pull from repository `docker-local`, the `latest` `busybox` image
        * `docker pull artifactory.jfrog.team/docker-local/busybox:latest`

### Steps to upgrade Artifactory Version

1. Login into the VM instance and sudo as root. Use the admin credentials provided in the install setup.  
Note: Use load balancer's NAT entries under Azure resources, to get the allocated NAT port for accessing the VM instance.

2. Upgrade artifactory with following [RPM instructions](https://www.jfrog.com/confluence/display/JCR/Upgrading+JFrog+Container+Registry#UpgradingJFrogContainerRegistry-RPMInstallation).
------
#### Note:
Supported locations: `East US 2`, `Central US`, `West Central US` and `West Europe`.  
Please check the Azure region support for `Standard Sku` property in load balancer for this template to work properly.  
Check for SQL server support on specified location. If SQL server is not available in the location, Use 'DB_Location' to specify the location with SQL server support.  


 