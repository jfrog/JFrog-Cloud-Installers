variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-1"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
}

variable "artifactory_version" {
  description = "Artifactory version to deploy"
  default     = "6.0.0"
}

variable "artifactory_license_1" {
  description = "Artifactory Enterprise License"
}

variable "artifactory_license_2" {
  description = "Artifactory Enterprise License"
}

variable "artifactory_license_3" {
  description = "Artifactory Enterprise License"
  default = ""
}

variable "artifactory_license_4" {
  description = "Artifactory Enterprise License"
  default = ""
}

variable "artifactory_license_5" {
  description = "Artifactory Enterprise License"
  default = ""
}

variable "volume_size" {
  description = "Disk size for each EC2 instances"
  default     = 250
}

variable "artifactory_instance_type" {
  default = "m4.xlarge"
  description = "Artifactory EC2 instance type"
}

variable "extra_java_options" {
  default = "-server -Xms2g -Xmx14g -Xss256k -XX:+UseG1GC -XX:OnOutOfMemoryError=\\\\\\\"kill -9 %p\\\\\\\""
  description = "Setting Java Memory Parameters for Artifactory. Learn about system requirements for Artifactory https://www.jfrog.com/confluence/display/RTF/System+Requirements#SystemRequirements-RecommendedHardware."
}

variable "bucket_name" {
  description = "AWS S3 Buket name"
  default     = "artifactory-enterprise-bucket"
}

variable "db_name" {
  description = "MySQL database name"
  default = "artdb"
}

variable "db_user" {
  description = "Database user name"
  default     = "artifactory"
}

variable "db_instance_class" {
  description = "The database instance type"
  default = "db.t2.small"
}

variable "db_password" {
  description = "Database password"
  default     = "password"
}

variable "db_allocated_storage" {
  description = "The size of the database (Gb)"
  default = "5"
}

variable "master_key" {
  description = "Master key for Artifactory cluster. Generate master.key using command '$openssl rand -hex 16'"
  default = "35767fa0164bac66b6cccb8880babefb"
}

variable "secondary_node_count" {
  description = "Desired number of Artifactory secondary nodes"
  default     = 0
}

variable "ssl_certificate" {
  description = "To use Artifactory as docker registry you need to provide wild card valid Certificate. Provide your SSL Certificate."
  default = "-----BEGIN CERTIFICATE----- MIIFhzCCA2+gAwIBAgIJALC4r5BQWZE4MA0GCSqGSIb3DQEBCwUAMFoxCzAJBgNV BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRMwEQYDVQQHDApTYW50YUNsYXJh MQswCQYDVQQKDAJJVDEUMBIGA1UEAwwLKi5sb2NhbGhvc3QwHhcNMTgwMTE3MTk0 NjI4WhcNMTkwMTA4MTk0NjI4WjBaMQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2Fs aWZvcm5pYTETMBEGA1UEBwwKU2FudGFDbGFyYTELMAkGA1UECgwCSVQxFDASBgNV BAMMCyoubG9jYWxob3N0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA 7KfOWDQlov8cMa8r/lcJqiWZaH9myQC74Vbe0HXsntQbcvljkjG2P7ebm5dd9Bzc sauNOJpbKf5AhFK1iwJUAkciGc1LR4k8wfWmQM3NPS8hrqrtH20zqNpdFRpNYjja JofwccPNm030GhhZkZ95TpruvmswMDwspl3jfqdcc/eiQsHcKyGnV2a+UAeoqe7J mHhmhRy1MLqAjF5U1GrUYUONA+22iRDJb4c9B91QoWvsnXpdA9NKV/mmA3/rIdx6 Ld2IPRdrIw2K5sAnXsh3bx2oCSvSfussf0x+4XDrnsaHVfjwvfNL8ECOuac2Oi/E WOp9528gOohpFAuwEt63Vl5p8/CC9m0HJDTZBKm2l5eD1kdPIj4PvP9Sn9CxGXKQ E1bxWoFxGX8EyRW0b0NK31N7b8JPZ1SoFNiB5amOMNLvR26a7cQrKumTuJeYK9Ja JaxhMXM7R0DA0Ev8ZG2xmyCygox+1KPSmJOIEpT70BFbj3rKLNqP22ET+zvPuh+2 DdgyrpHFeYkGWjMbWPjK7wJsD2zM8ccoJQfepPz8I4rT0JfrKAQgCGuGOggneaNJ KTVGNOFbj5AXdZ/Q+GvNommyRdq4J7EnqY6L+P25fo5qZ6UZ/iS0tPcvxgn0Fdhs pUPbQyQIDZyxZd3Q1lUIE38ol8P66mS2zbzf8EeOCoUCAwEAAaNQME4wHQYDVR0O BBYEFETAQM/5P7XJ8kevHFj6BPndQOFaMB8GA1UdIwQYMBaAFETAQM/5P7XJ8kev HFj6BPndQOFaMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggIBAJ1TepKv LWYhFmVQcgZwZf/qt1a1cohzJSm6da9RCnnAWC7WC/U117bgSomtrH1v0OysHFhB zBBUeBqI7+OmzAX8dhj+roKkcnFUM/IwlK1eueIIA//CWvEf/o0XExilVS2yCc9d PTpOQBXwk9QinxK36kHdBiGxa7dW0JPnOEEmuMgGORKeLy4J6Ik8iSeFY1SZVcOI +6WWvoKciPlmIeccC+6YVmkeBwhP2o5r5w/UAaO2hSnGvmm4UIj/VJv4VQu7xTUp cIfFz5NtIr80DbqcyPiEMS2ETJ4L/kO4MS5FfeEXyQuXCzmiIDVY6tE3C7+kZmK4 JzPLuWm9ndQoyQySOGfQqvlUR1+YxUdvmu3LrOS5dOA354Q36wHa4wEGUoHU/7GV fYQmmmDSDaNSpXW5PFey6scFyDBS/yYJ0H9EjYb/11HeWYj8Yv5xTWj8nhzJONC8 D6Y5ydlU4PifM2pOf88pTYpmogNwLJWXbql5I9cvMa8APo4yLVqcISU5ynsvFke+ Non+T0mHpJai/hrA9NK+s6EGC1dAX58jy61h6FhOPI1d4s/mov/KMa2t3SfZp5SF 81aR6dHvO56teiK5M1xMkrqG75zh3TMFJJLRFe9XxeB4JeN76URB3mgADOUqkBxd ibSgVqfKwOw4IujEcqMUc5mqSnbLY1Dv+oby -----END CERTIFICATE-----"
}

variable "ssl_certificate_key" {
  description = "Provide your SSL Certificate key"
  default = "-----BEGIN PRIVATE KEY----- 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 S+j1+iUKGGhwVmhqh75q5do3+VF3XlAh -----END PRIVATE KEY-----"
}

variable "certificate_domain" {
  description = "Provide your Certificate Domain Name. For e.g jfrog.team for certificate with *.jfrog.team"
  default = "artifactory"
}

variable "artifactory_server_name" {
  description = "Provide artifactory server name to be used in Nginx. e.g artifactory for artifactory.jfrog.team"
  default = "artifactory"
}

variable "aws_amis" {
  type = "map"
  default = {
    us-east-1 = "ami-6869aa05"
    us-west-2 = "ami-7172b611"
    us-west-1 = "ami-31490d51"
    us-west-2 = "ami-7172b611"
    eu-west-1 = "ami-f9dd458a"
    eu-west-2 = "ami-886369ec"
    eu-central-1 = "ami-ea26ce85"
    ap-northeast-1 = "ami-374db956"
    ap-northeast-2 = "ami-2b408b45"
    ap-southeast-1 = "ami-a59b49c6"
    ap-southeast-2 = "ami-dc361ebf"
    ap-south-1 = "ami-ffbdd790"
    us-east-2 = "ami-f6035893"
    ca-central-1 ="ami-730ebd17"
    sa-east-1 = "ami-6dd04501"
    cn-north-1 = "ami-8e6aa0e3"
  }
}
