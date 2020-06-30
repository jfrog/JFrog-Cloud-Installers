# Terraform Template For Artifactory Enterprise 
*Note: This Terraform template is no longer maintained.  Feel free to review this code for your own POC concepts, but we are not continuing to update it or add features. We do plan to revive this in the future with a better implementation.*

### Prerequisites:
* An AWS account
* Basic knowledge of AWS
* Predefined Keys 
* Basic knowledge of Artifactory
* Learn about [system requirements for Artifactory](https://www.jfrog.com/confluence/display/RTF/System+Requirements#SystemRequirements-RecommendedHardware)
* Learn more about Terraform AWS provider follow: https://www.terraform.io/docs/providers/aws/index.html

### Steps to Deploy Artifactory Enterprise Using Terraform Template
1. Set your AWS account credentials by setting environment variables: 
   ```
       export AWS_ACCESS_KEY_ID="your_access_key"
       export AWS_SECRET_ACCESS_KEY="your_secret_key"
       export AWS_DEFAULT_REGION="aws_region"
   ```
   To learn more about Terraform aws provider follow there documentation.
   https://www.terraform.io/docs/providers/aws/index.html

2. Modify the default values in the `variables.tf` file  
    
3. Pass the Artifactory Enterprise licenses as a string in the variables `artifactory_license_1-5`.  
   For example: Change disk space to 500Gb:
   ```
    variable "volume_size" {
      description = "Disk size for each EC2 instances"
      default     = 500
    }
   ```
4. Run the `terraform init -var 'key_name=myAwsKey'` command. This will install the required plugin for the AWS provider.

5. Run the `terraform plan -var 'key_name=myAwsKey'` command.

6. Run the `terraform apply -var 'key_name=myAwsKey'` command to deploy Artifactory Enterprise cluster on AWS
   
    **Note**: it takes approximately 15 minutes to bring up the cluster.

7. You will receive ELB Url to access Artifactory. By default, this template starts only one node in the Artifactory cluster. 
   It takes 7-10 minutes for Artifactory to start and to attach the instance to the ELB.The output can be viewed as:
    ```
    Outputs:
    
    address = artifactory-elb-265664219.us-west-2.elb.amazonaws.com
    ```

8. Access the Artifactory UI using ELB Url provided in outputs.

9. Scale your cluster using following command: `terraform apply -var 'key_name=myAwsKey' -var 'secondary_node_count=2'`
   In this example we are scaling artifactory cluster to 2 nodes.
   
    **Note**: You can only scale nodes to number of artifactory licenses you have available for cluster.

10. SSH into Artifactory primary instance and type [inactiveServerCleaner](inactiveServerCleaner.groovy) plugin in `'/var/opt/jfrog/artifactory/etc/plugins'` directory.
    (Optional) To destroy the cluster, run  the following commend: `terraform destroy -var 'key_name=myAwsKey'`

### Note:
* This template only supports Artifactory version 5.8.x and above.
* Turn off daily backups. Read Documentation provided [here](https://www.jfrog.com/confluence/display/RTF/Managing+Backups).
  
  **Note**: In this template as default S3 is default filestore and data is persisted in S3. If you keep daily backups on disk space (default 250Gb) will get occupied quickly.
* Use an SSL Certificate with a valid wildcard to your artifactory as docker registry with subdomain method.

### Steps to setup Artifactory as secure docker registry
Considering you have SSL certificate for `*.jfrog.team`
1. Pass your SSL Certificate in variable `ssl_certificate` as string
2. Pass your SSL Certificate Key in variable `ssl_certificate_key` as string
3. Set `certificate_domain` as `jfrog.team`
4. Set `artifactory_server_name` as `artifactory` if you want to access artifactory with `https://artifactory.jfrog.team`
5. Create DNS for example Route53 with entry `artifactory.jfrog.team` pointing to ELB value provided as output in Terraform Stack.
6. Create DNS for example Route53 with entry `*.jfrog.team pointing` to ELB value provided as output in Terraform Stack.
7. If you have virtual docker registry with name `docker-virtual` in artifactory. You can access it via `docker-virtual.jfrog.team` e.g `docker pull docker-virtual.jfrog.team/nginx`

### Steps to upgrade Artifactory Version
1. Change the value of `artifactory_version` from old version to new Artifactory version you want to deploy. for e.g. `5.8.1` to `5.8.2`.

2. Run command `terraform apply -var 'key_name=myAwsKey' -var 'secondary_node_count=2' -ver 'artifactory_version=5.8.2'`.
   You will see instances will get upgraded one by one. Depending on your cluster size it will take 20-30 minutes to update stack.

### Use Artifactory as backend
To to store state as an artifact in a given repository of Artifactory, see [https://www.terraform.io/docs/backends/types/artifactory.html](https://www.terraform.io/docs/backends/types/artifactory.html)

