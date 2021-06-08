#!/bin/bash
set -ex
# keep track of the last executed command
#trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
#trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

# This file publicly publishes the modules
# following commands are needed only one time per account per region

# all_regions=( us-east-1 us-east-2 us-west-1 us-west-2 sa-east-1 ca-central-1 af-south-1 eu-central-1 eu-west-1 eu-west-2 eu-south-1 eu-west-3 eu-north-1 ap-northeast-3 ap-northeast-2 ap-northeast-1 ap-south-1 ap-southeast-1 ap-southeast-2 )
#  fails in following regions -> af-south-1 eu-central-1 eu-south-1 
regions=( eu-west-2 eu-south-1 eu-west-3 eu-north-1 ap-northeast-3 ap-northeast-2 ap-northeast-1 ap-south-1 ap-southeast-1 ap-southeast-2 )
PROFILE=seller

# 1) create appropriate profile in ~/.aws/credentials file

# 2) Download the beta service model definition to be plugged in to AWS CLI
aws --profile $PROFILE s3 cp s3://uno-beta-sdk/c2j-output-2021-01-11/cloudformation/2010-05-15/service-2.json .

for i in "${!regions[@]}"; do 
  export REGION="${regions[$i]}"

    # 3) Add downloaded model to your AWS CLI
    printf "3. add-model: %s\n" "$REGION"
    echo aws --profile $PROFILE --region $REGION configure add-model --service-model "file://service-2.json" --service-name Uno
    aws --profile $PROFILE --region $REGION configure add-model --service-model "file://service-2.json" --service-name Uno

    # 4) Verify Model
    # printf "4. verify model: %s:\n" "$REGION"
    # echo aws --profile $PROFILE --region $REGION Uno help | grep register-publisher
    # aws --profile $PROFILE --region $REGION Uno help | grep register-publisher

    # 5) Register
    printf "5. register: %s\n" "$REGION"
    echo aws --profile $PROFILE --region $REGION Uno register-publisher --accept-terms-and-conditions
    aws --profile $PROFILE --region $REGION Uno register-publisher --accept-terms-and-conditions
done
