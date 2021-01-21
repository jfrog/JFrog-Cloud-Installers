#!/usr/bin/env bash
VERSION=$1
EDITIONS=( artifactory-pro artifactory-jcr )

#for loop start: editoins
for EDITION in "${EDITIONS[@]}"
do
  UPSTREAM_IMAGE_NAME=releases-docker.jfrog.io/jfrog/$EDITION
  BUILD_IMAGE_NAME=709825985650.dkr.ecr.us-east-1.amazonaws.com/jfrog/$EDITION
  ARTIFACTORY_PASSWORD=corona1831

  # Logic starts here
  if [ -z "$VERSION" ]
  then
        echo "No version passed in. Build failed."
        echo "usage: buildAwsContainers <vesion>"
        echo "example: buildAwsContainers 7.2.1 "
        exit -1
  fi

  # Extract and modify the entrypoint to run out custom code for first-time password
  docker pull $UPSTREAM_IMAGE_NAME:$VERSION
  docker run -d --rm --name tmp-docker $UPSTREAM_IMAGE_NAME:$VERSION
  docker cp tmp-docker:/entrypoint-artifactory.sh original-entrypoint.sh
  docker rm -f tmp-docker
  perl -pe 's/^addExtraJavaArgs$/`cat extra_conf`/ge' original-entrypoint.sh > entrypoint-artifactory.sh

  #Create installer-info file
  if [ "$EDITION" == "artifactory-pro" ]
  then
    cat <<EOF > installer-info.json
    {
      "productId": "CloudFormation_artifactory-ha/$VERSION",
      "features": [
        {
          "featureId": "Partner/ACC-006973"
        }
      ]
    }
EOF
  else
    cat <<EOF > installer-info.json
    {
      "productId": "CloudFormation_artifactory-jcr/$VERSION",
      "features": [
        {
          "featureId": "Partner/ACC-006973"
        }
      ]
    }
EOF
  fi
  cat installer-info.json

  # Create the new docker image
  docker build --no-cache --build-arg UPSTREAM_TAG=$VERSION -t $BUILD_IMAGE_NAME:$VERSION .

  # Run minimal test
  set -x
  docker run --name test-new-image -d -e ARTIFACTORY_PASSWORD=$ARTIFACTORY_PASSWORD -p 8081:8081 -p 8082:8082 $BUILD_IMAGE_NAME:$VERSION
  # Wait for it to come up
  SUCCESS=false
  for i in {1..30}
  do
      STATUS=$(docker exec test-new-image curl -u admin:$ARTIFACTORY_PASSWORD http://localhost:8082/router/api/v1/system/health | jq .services[0].state)
      if [ "$STATUS" == "\"HEALTHY\"" ]; then
          echo "Build successful!"
          SUCCESS=true
          break
      fi
      echo "Container is not up yet, waiting 10 seconds..."
      sleep 10
  done

  #clearnup
  docker stop test-new-image
  docker rm test-new-image
  rm installer-info.json


  if [ "$SUCCESS" = true ] ; then
    echo "Test Succeeded. Build succeeded."
  else
    echo "Test failed. Build failed. Removing docker image"
    exit 1
  fi
  #for loop endL: editions
done
