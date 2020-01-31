.PHONY: help run submodules

submodules:
	git submodule init
	git submodule update
	cd submodules/quickstart-linux-bastion && git submodule init && git submodule update 
	cd submodules/quickstart-amazon-eks && git submodule init && git submodule update 

help:
	@echo   "make test  : executes taskcat"

create:
	aws cloudformation create-stack --stack-name test --template-body file://$(pwd)/templates/jfrog-artifactory-ec2-new-vpc.template --parameters $(cat .ignore/params) --capabilities CAPABILITY_IAM

delete:
	aws cloudformation delete-stack --stack-name test

.ONESHELL:
test: lint submodules
	cd .. && pwd && taskcat -c theflash/ci/config.yml -n

lint:
	time taskcat -l -c ci/config.yml

public_repo:
	taskcat -c theflash/ci/config.yml -u
	#https://taskcat-tag-quickstart-jfrog-artifactory-c2fa9d34.s3-us-west-2.amazonaws.com/quickstart-jfrog-artifactory/templates/jfrog-artifactory-ec2-master.template
	#curl https://taskcat-tag-quickstart-jfrog-artifactory-7008506c.s3-us-west-2.amazonaws.com/quickstart-jfrog-artifactory/templates/jfrog-artifactory-ec2-master.template

get_public_dns:
	aws elb describe-load-balancers | jq '.LoadBalancerDescriptions[]| .CanonicalHostedZoneName'

get_bastion_ip:
	aws ec2 describe-instances | jq '.[] | select(.[].Instances[].Tags[].Value == "LinuxBastion") '
