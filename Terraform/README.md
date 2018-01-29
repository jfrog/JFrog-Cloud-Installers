# Terraform Template For Artifactory Enterprise

### Prerequisites:
* AWS account
* Basic knowledge to AWS
* Pre created Keys
* Basic knowledge of Artifactory
* Learn about [system requirements for Artifactory](https://www.jfrog.com/confluence/display/RTF/System+Requirements#SystemRequirements-RecommendedHardware)

### Steps to Deploy Artifactory Enterprise using Terraform template

1. Set your AWS account credentials.
   Easy way to do it is by setting environment variables.
   ```
      export AWS_ACCESS_KEY_ID="your_access_key"
      export AWS_SECRET_ACCESS_KEY="your_secret_key"
      export AWS_DEFAULT_REGION="aws_region"
    ```
   To learn more about Terraform aws provider follow there documentation.
   https://www.terraform.io/docs/providers/aws/index.html
   
2. Make Changes in `variables.tf` file to change default values to desired once. Also pass Artifactory Enterprise licenses as string in Variables `artifactory_license_1-5`."
   e.g Change disk space to 500Gb:
   ```
   variable "volume_size" {
     description = "Disk size for each EC2 instances"
     default     = 500
   }
   ```

3. Run command `terraform init -var 'key_name=myAwsKey'`
   This is install required plugin for AWS provider.

4. Run command `terraform plan -var 'key_name=myAwsKey'`.

5. Run command `terraform apply -var 'key_name=myAwsKey'` to deploy Artifactory Enterprise cluster on AWS.
   
   It will take approximately 15 min to bring up cluster. 
   
   You will get ELB Url to access Artifactory.By default This template will start only 1 node in Artifactory cluster.
   It takes 7-10 minutes for Artifactory to start and attach instance to ELB.
   ```
   Outputs:
   
   address = artifactory-elb-265664219.us-west-2.elb.amazonaws.com
    ```
   
6. Access Artifactory UI using ELB Url provided in outputs.

7. Scale your cluster using following command: 

   `terraform apply -var 'key_name=myAwsKey' -var 'secondary_node_count=2'`
   
   In this example we are scaling artifactory cluster to 2 nodes.   
   
   Note: You can only scale nodes to number of artifactory licenses you have available for cluster.
   
8. SSH into Artifactory primary instance and write [inactiveServerCleaner](inactiveServerCleaner.groovy) plugin in '/var/opt/jfrog/artifactory/etc/plugins' directory.

9. Command to destroy cluster:
   `terraform destroy -var 'key_name=myAwsKey'`
   
### Note: 
1. This template only supports Artifactory version 5.8.x and above.
2. Turn off daily backups.  Read Documentation provided [here](https://www.jfrog.com/confluence/display/RTF/Managing+Backups)
3. Use SSL Certificate with valid wild card to you artifactory as docker registry with subdomain method.

### Steps to setup Artifactory as secure docker registry
considering you have SSL certificate for `*.jfrog.team`
1. Pass your SSL Certificate in variable `ssl_certificate` as string
2. Pass your SSL Certificate Key in variable `ssl_certificate_key` as string
3. Set `certificate_domain` as `jfrog.team`
4. Set `artifactory_server_name` as `artifactory` if you want to access artifactory with `https://artifactory.jfrog.team`
5. Create DNS for example Route53 with entry `artifactory.jfrog.team` pointing to ELB value provided as output in CloudFormation Stack.
6. Create DNS for example Route53 with entry `*.jfrog.team` pointing to ELB value provided as output in CloudFormation Stack.
7. If you have virtual docker registry with name `docker-virtual` in artifactory. You can access it via `docker-virtual.jfrog.team`
   e.g ```docker pull docker-virtual.jfrog.team/nginx```


### Steps to upgrade Artifactory Version 
1. Change value of `artifactory_version` from old version to new Artifactory version you want to deploy.
   for e.g. 5.8.1 to 5.8.2
   Run command `terraform apply -var 'key_name=myAwsKey' -var 'secondary_node_count=2' -ver 'artifactory_version=5.8.2'`.
        
2. You will see instances will get upgraded one by one. Depending on your cluster size it will take 20-30 minutes to update stack.
   