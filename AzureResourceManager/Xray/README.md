# Setup JFrog Xray
The recommended way of deploying is through the Azure marketplace.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjfrog%2FJFrog-Cloud-Installers%2Fmaster%2FAzureResourceManager%2FXray%2Fazuredeploy_xray_vmss.json" target="_blank">
<img src="https://aka.ms/deploytoazurebutton"/>
</a>

This template can help you setup  [JFrog Xray](https://jfrog.com/xray/) on Azure.

## Prerequisites 
1. JFrog Xray is an addition to JFrog Artifactory. 
    * To be able to use it, you need to have an Artifactory instance deployed in Azure with the appropriate license. If you do not have an Xray compatible license, you can [get a free trial](https://jfrog.com/xray/free-trial/).

2. Deployed Postgresql instance (if "existing DB" is selected as a parameter).

## Postgresql deployment
You can deploy a compatible Postgresql instance using this link:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjfrog%2FJFrog-Cloud-Installers%2Farm-xray%2FAzureResourceManager%2FPostgresql%2FazurePostgresDBDeploy.json" target="_blank">
<img src="https://aka.ms/deploytoazurebutton"/>
</a>

In the Databases field, use the object: 

```
  {
    "properties": [
      {
        "name": "xray",
        "charset": "UTF8",
        "collation": "English_United States.1252"
      }
    ]
  }
```

## Installation
1. Click "Deploy to Azure" button. If you don't have an Azure subscription, it will guide you on how to signup for a free trial.

2. Fill out the form. Make sure to use the Artifactory Join key, which you can copy from the Artifactory UI, Security -> Settings -> Connection details 

3. Click Review + Create, then click Create to start the deployment 

4. Once deployment is done, access Xray thru Artifactory UI, Security & Compliance menu




### Note: 
1. This template only supports Xray versions 3.2.x and above.
2. Input values for 'adminUsername' and 'adminPassword' parameters needs to follow azure VM access rules.

### Steps to upgrade JFrog Xray version

ARM templates uses a debian installation and you can follow the [official instructions](https://www.jfrog.com/confluence/display/JFROG/Upgrading+Xray#UpgradingXray-InteractiveScriptUpgrade(recommended).1) but for your convenience, you can use this method.

SSH to the Xray VM and CD to the /opt/ folder. Create an empty file upgrade.sh

``touch upgrade.sh``

Make the file executable:

```chmod +x upgrade.sh```

Open the file 

```vi upgrade.sh```

Paste the commands below (check the version of Xray you want to upgrade to):
```
cd /opt/
echo "### Stopping Xray service before upgrade ###"
systemctl stop xray.service
XRAY_VERSION=3.6.2
wget -O jfrog-xray-${XRAY_VERSION}-deb.tar.gz https://api.bintray.com/content/jfrog/jfrog-xray/xray-deb/${XRAY_VERSION}/jfrog-xray-${XRAY_VERSION}-deb.tar.gz?bt_package=jfrog-xray
tar -xvf jfrog-xray-${XRAY_VERSION}-deb.tar.gz
rm jfrog-xray-${XRAY_VERSION}-deb.tar.gz
cd jfrog-xray-${XRAY_VERSION}-deb
echo "### Run Xray installation script ###"
echo "y" | ./install.sh
echo "### Start Xray service ###"
systemctl start xray.service
```
Run the script

```./upgrade.sh```

The script will upgrade existing 3.x version of Xray to the given version. Check /var/opt/jfrog/xray/console.log to make sure that the service was properly started. Look for the message:
```All services started successfully in 10.743 seconds```
and check the application version in the log. 

