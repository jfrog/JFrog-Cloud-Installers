# JFrog Container Registry for AWS Container Marketplace

JFrog Container Registry can be installed into either an ECS or EKS cluster.

### Prerequisites
* AWS account
* EKS or ECS cluster
#### Recommended requirements
* S3
* ELB/ALB
* RDS
* Valid SSL certificate
* EBS (for persistent storage)

### For testing only

To simply get up and running, you can try:

```docker run -d -p 8081:8081 <image-url>```
After this, you can access the UI at \<URL\>:8081. The default username is 'admin'. See 'Getting or setting initial password' to find out how to get the initial password.

### Getting or setting initial password
If no initial password is provided for the default user 'admin', one will be generated and saved to the container at '/var/opt/jfrog/artifactory/generated-pass.txt'. 

You can print it out with a Docker command:
```docker exec -it <container-id> cat /var/opt/jfrog/artifactory/generated-pass.txt```

You can also set a default password by passing it as an environment variable (ARTIFACTORY_PASSWORD) during container creation:
```docker run -d -p 8081:8081 --env ARTIFACTORY-PASSWORD=<PASSWORD> <image-url>```


### For production

1. Set up an [RDS](https://aws.amazon.com/rds/) (PSQL is the preferred database)
2. Set up an [S3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html#create-bucket-intro)
3. Run the Docker image, pointing it to the RDS, S3 and to some persistent storage (EBS)
    * See [S3 Binarystore Configuration](https://www.jfrog.com/confluence/display/JCR/Configuring+the+Filestore#ConfiguringtheFilestore-AmazonS3OfficialSDKTemplate) for more information 
    * See [Configuring the databse](https://www.jfrog.com/confluence/display/JCR/Configuring+the+Database) for more information
    * See [Extra Configuration](https://www.jfrog.com/confluence/display/JCR/Installing+with+Docker#InstallingwithDocker-ExtraConfigurationDirectory) to learn how to pass this information to the Docker container
    * Create a medium sized mount point (~50GB) on /var/opt/jfrog/artifactory. See [Managing Data Persistence](https://www.jfrog.com/confluence/display/JCR/Installing+with+Docker#InstallingwithDocker-ManagingDataPersistence)
4. Expose the service (running on port 8081) via a load balancer to port 443
    * Docker requires a valid SSL certificate
5. Learn how to use your [JFrog Container Registry](https://www.jfrog.com/confluence/display/JCR/Overview)
    * See 'Getting or setting initial password'


