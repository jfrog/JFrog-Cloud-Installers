# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Declare the data source
data "aws_availability_zones" "available" {}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default_2" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_subnet" "default_3" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "artifactory_elb"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#IAM user for S3
resource "aws_iam_user" "s3" {
  name = "s3-access"
}

#IAM access key for S3
resource "aws_iam_access_key" "s3" {
  user = "${aws_iam_user.s3.name}"
}

# S3 bucket
resource "aws_s3_bucket" "b" {
  bucket = "${var.bucket_name}"
  acl    = "private"
}

#IAM Policy
resource "aws_iam_user_policy" "lb_ro" {
  user = "${aws_iam_user.s3.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
      "arn:aws:s3:::${aws_s3_bucket.b.id}/*",
      "arn:aws:s3:::${aws_s3_bucket.b.id}"
      ]
    }
  ]
}
EOF
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "artifactory_sg"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from the VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from the VPC
  ingress {
    from_port   = 10001
    to_port     = 10001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from the VPC
  ingress {
    from_port   = 6061
    to_port     = 6061
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#RDS Security Group
resource "aws_security_group" "main_db_access" {
  description = "Allow access to the database"
  vpc_id      = "${aws_vpc.default.id}"
}

resource "aws_security_group_rule" "allow_db_access" {
  type = "ingress"

  from_port   = "3306"
  to_port     = "3306"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.main_db_access.id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.main_db_access.id}"
}

resource "aws_db_subnet_group" "main_db_subnet_group" {
  name        = "db-subnetgrp"
  description = "RDS subnet group"
  subnet_ids  = ["${aws_subnet.default.id}","${aws_subnet.default_2.id}","${aws_subnet.default_3.id}"]

}

#RDS to for Artifactory
resource "aws_db_instance" "default" {
  allocated_storage    = "${var.db_allocated_storage}"
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.5"
  instance_class       = "${var.db_instance_class}"
  name                 = "${var.db_name}"
  username             = "${var.db_user}"
  password             = "${var.db_password}"
  multi_az             = "false"
  vpc_security_group_ids   = ["${aws_security_group.main_db_access.id}"]
  skip_final_snapshot  = "true"
  db_subnet_group_name = "${aws_db_subnet_group.main_db_subnet_group.name}"
}

resource "aws_elb" "web" {
  name = "artifactory-elb"

  subnets         = ["${aws_subnet.default_2.id}","${aws_subnet.default_3.id}"]
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
     healthy_threshold   = 3
     unhealthy_threshold = 3
     timeout             = 15
     target              = "HTTP:80/artifactory/webapp/#/login"
     interval            = 30
   }
}

resource "aws_cloudformation_stack" "autoscaling_group" {
  name = "artifactory-asg"
  template_body = <<EOF
{
  "Resources": {
    "MyAsg": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "AvailabilityZones": ["${aws_subnet.default_2.availability_zone}","${aws_subnet.default_3.availability_zone}"],
        "VPCZoneIdentifier": ["${aws_subnet.default_2.id}","${aws_subnet.default_3.id}"],
        "LaunchConfigurationName": "${aws_launch_configuration.master.name}",
        "MaxSize": "2",
        "MinSize": "1",
        "DesiredCapacity": "1",
        "LoadBalancerNames": ["${aws_elb.web.name}"],
        "HealthCheckType": "ELB",
        "HealthCheckGracePeriod" : "480"
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "0",
          "MaxBatchSize": "1",
          "PauseTime": "PT7M"
        }
      }
    }
  },
  "Outputs": {
    "AsgName": {
      "Description": "The name of the auto scaling group",
       "Value": {"Ref": "MyAsg"}
    }
  }
}
EOF
}

resource "aws_autoscaling_policy" "my_policy" {
  name = "my-policy"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_cloudformation_stack.autoscaling_group.outputs["AsgName"]}"
}

resource "aws_cloudformation_stack" "autoscaling_group_secondary" {
  name = "artifactory-secondary-asg"
  template_body = <<EOF
{
  "Resources": {
    "MySecondaryAsg": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "AvailabilityZones": ["${aws_subnet.default_2.availability_zone}","${aws_subnet.default_3.availability_zone}"],
        "VPCZoneIdentifier": ["${aws_subnet.default_2.id}","${aws_subnet.default_3.id}"],
        "LaunchConfigurationName": "${aws_launch_configuration.secondary.name}",
        "MaxSize": "9",
        "MinSize": "0",
        "DesiredCapacity": "${var.secondary_node_count}",
        "LoadBalancerNames": ["${aws_elb.web.name}"],
        "HealthCheckType": "ELB",
        "HealthCheckGracePeriod" : "480"
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "1",
          "MaxBatchSize": "1",
          "PauseTime": "PT7M"
        }
      }
    }
  },
  "Outputs": {
    "SecondaryAsgName": {
      "Description": "The name of the auto scaling group",
       "Value": {"Ref": "MySecondaryAsg"}
    }
  }
}
EOF
}

resource "aws_autoscaling_policy" "my_secondary_policy" {
  name = "my-secondary-policy"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_cloudformation_stack.autoscaling_group_secondary.outputs["SecondaryAsgName"]}"
}


resource "aws_launch_configuration" "master" {
    image_id = "${lookup(var.aws_amis, var.aws_region)}"

    instance_type = "${var.artifactory_instance_type}"

    # The name of our SSH keypair we created above.
    key_name = "${var.key_name}"

    security_groups = ["${aws_security_group.default.id}"]

    associate_public_ip_address = true

    user_data = "${data.template_file.init.rendered}"

    root_block_device {
        volume_type = "gp2"
        volume_size = "${var.volume_size}"
        delete_on_termination = true
    }

    lifecycle {
      create_before_destroy = true
    }
}

data "template_file" "init" {
  template = "${file("userdata.sh")}"

  vars = {
    s3_bucket_name = "${aws_s3_bucket.b.id}"
    s3_bucket_region = "${aws_s3_bucket.b.region}"
    s3_access_key = "${aws_iam_access_key.s3.id}"
    s3_secret_key = "${aws_iam_access_key.s3.secret}"
    db_url = "${aws_db_instance.default.endpoint}"
    db_name = "${aws_db_instance.default.name}"
    db_user = "${aws_db_instance.default.username}"
    db_password = "${aws_db_instance.default.password}"
    master_key = "${var.master_key}"
    artifactory_version = "${var.artifactory_version}"
    artifactory_license_1 = "${var.artifactory_license_1}"
    artifactory_license_2 = "${var.artifactory_license_2}"
    artifactory_license_3 = "${var.artifactory_license_3}"
    artifactory_license_4 = "${var.artifactory_license_4}"
    artifactory_license_5 = "${var.artifactory_license_5}"
    ssl_certificate = "${var.ssl_certificate}"
    ssl_certificate_key = "${var.ssl_certificate_key}"
    certificate_domain = "${var.certificate_domain}"
    artifactory_server_name = "${var.artifactory_server_name}"
    EXTRA_JAVA_OPTS = "${var.extra_java_options}"
  }
}

resource "aws_launch_configuration" "secondary" {
  image_id = "${lookup(var.aws_amis, var.aws_region)}"

  instance_type = "${var.artifactory_instance_type}"

  # The name of our SSH keypair we created above.
  key_name = "${var.key_name}"

  security_groups = ["${aws_security_group.default.id}"]

  associate_public_ip_address = true

  user_data = "${data.template_file.secondary_init.rendered}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.volume_size}"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "secondary_init" {
  template = "${file("userdata_secondary.sh")}"

  vars = {
    s3_bucket_name = "${aws_s3_bucket.b.id}"
    s3_bucket_region = "${aws_s3_bucket.b.region}"
    s3_access_key = "${aws_iam_access_key.s3.id}"
    s3_secret_key = "${aws_iam_access_key.s3.secret}"
    db_url = "${aws_db_instance.default.endpoint}"
    db_name = "${aws_db_instance.default.name}"
    db_user = "${aws_db_instance.default.username}"
    db_password = "${aws_db_instance.default.password}"
    master_key = "${var.master_key}"
    artifactory_version = "${var.artifactory_version}"
    artifactory_license_1 = "${var.artifactory_license_1}"
    artifactory_license_2 = "${var.artifactory_license_2}"
    artifactory_license_3 = "${var.artifactory_license_3}"
    artifactory_license_4 = "${var.artifactory_license_4}"
    artifactory_license_5 = "${var.artifactory_license_5}"
    ssl_certificate = "${var.ssl_certificate}"
    ssl_certificate_key = "${var.ssl_certificate_key}"
    certificate_domain = "${var.certificate_domain}"
    artifactory_server_name = "${var.artifactory_server_name}"
    EXTRA_JAVA_OPTS = "${var.extra_java_options}"
  }
}
