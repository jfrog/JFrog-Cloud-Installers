#!/bin/bash
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT


# list of regions, folder names and corresponding module names
# 2 regions where modules are not available: us-gov-east-1, us-gov-west-1
# 4 regions are opt in so modules were not published: af-south-1 eu-south-1 ap-east-1 me-south-1
# all_regions=( us-east-1 us-east-2 us-west-1 us-west-2 sa-east-1 ca-central-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 eu-north-1 ap-northeast-3 ap-northeast-2 ap-northeast-1 ap-south-1 ap-southeast-1 ap-southeast-2 )
# all_folders=( JFrog-Artifactory-EC2Instance-MODULE JFrog-Xray-EC2Instance-MODULE JFrog__Artifactory__Core__MODULE aws-vpc-module linux-bastion-module JFrog__Artifactory__ExistingVpc__MODULE JFrog__Artifactory__NewVpc__MODULE )
# all_modules=( JFrog::Artifactory::EC2Instance::MODULE JFrog::Xray::EC2Instance::MODULE JFrog::Artifactory::Core::MODULE JFrog::Vpc::MultiAz::MODULE JFrog::Linux::Bastion::MODULE JFrog::Artifactory::ExistingVpc::MODULE JFrog::Artifactory::NewVpc::MODULE )
regions=( us-east-1 us-east-2 us-west-1 us-west-2 sa-east-1 ca-central-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 eu-north-1 ap-northeast-3 ap-northeast-2 ap-northeast-1 ap-south-1 ap-southeast-1 ap-southeast-2 )
folders=( JFrog__Artifactory__ExistingVpc__MODULE JFrog__Artifactory__NewVpc__MODULE )
modules=( JFrog::Artifactory::ExistingVpc::MODULE JFrog::Artifactory::NewVpc::MODULE )

for i in "${!regions[@]}"; do 
  export REGION="${regions[$i]}"
  for j in "${!folders[@]}"; do 
    export FOLDER="${folders[$j]}"
    export MODULE="${modules[$j]}"
    export VERSION=$( aws cloudformation list-type-versions --type MODULE --type-name $MODULE --region $REGION | jq '.TypeVersionSummaries[-1].VersionId' | tr -d "\"")
    printf "1. start        : %s:%s:%s\n" "$REGION" "$MODULE" "$VERSION"

    cd Amazon/cloudformation-modules/$FOLDER

    printf "2. submitting   : %s:%s:%s\n" "$REGION" "$MODULE" "$VERSION"
    cfn submit --set-default --region $REGION

    export VERSION=$( aws cloudformation list-type-versions --type MODULE --type-name $MODULE --region $REGION | jq '.TypeVersionSummaries[-1].VersionId' | tr -d "\"")
    printf "3. submit done  : %s:%s:%s\n" "$REGION" "$MODULE" "$VERSION"

    ARN=$(echo arn:aws:cloudformation:$REGION:595206835686:type/module/$MODULE | sed 's/::/-/g')

    printf "4. starting test: %s:%s:%s:%s\n" "$REGION" "$MODULE" "$VERSION" "$ARN"
    echo $(aws cloudformation test-type --region $REGION --type MODULE --arn $ARN) # --public-version-number OPTIONAL_READ_NOTE_ABOVE

    typeTestStatus=""
    while [ "$typeTestStatus" != "\"PASSED\"" ]
    do
      typeTestStatus=$(aws cloudformation describe-type --type MODULE  --region $REGION --arn $ARN/$VERSION | jq '.TypeTestsStatus')
      echo "typeTestStatus  : $typeTestStatus"
      sleep 5
    done
    printf "5. publishing   : %s:%s:%s\n" "$REGION" "$MODULE" "$VERSION"
    echo $(aws cloudformation publish-type --region $REGION --type MODULE --arn $ARN) # --public-version-number OPTIONAL_READ_NOTE_ABOVE
    printf "6. published    : %s:%s:%s\n" "$REGION" "$MODULE" "$VERSION"
    cd ../../..
  done
done