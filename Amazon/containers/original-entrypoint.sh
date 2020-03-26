#!/bin/bash
#
# An entrypoint script for Artifactory to allow custom setup before server starts
#
: ${ARTIFACTORY_NAME:=artifactory}

JF_ARTIFACTORY_PID=${JF_PRODUCT_HOME}/app/run/${ARTIFACTORY_NAME}.pid

. ${JF_PRODUCT_HOME}/app/bin/installerCommon.sh

ARTIFACTORY_BIN_FOLDER=${JF_PRODUCT_HOME}/app/bin

sourceScript(){
    local file=$1

    [ ! -z "${file}" ] || errorExit "target file is not passed to source a file"
    [   -f "${file}" ] || errorExit "${file} file is not found"
    source "${file}"   || errorExit "Unable to source ${file}, please check if the $USER user has permissions to perform this action"
}

initHelpers(){
    local systemYamlHelper="${ARTIFACTORY_BIN_FOLDER}"/systemYamlHelper.sh
    local installerCommon="${ARTIFACTORY_BIN_FOLDER}"/installerCommon.sh
    local artCommon="${ARTIFACTORY_BIN_FOLDER}"/artifactoryCommon.sh

    export YQ_PATH="${ARTIFACTORY_BIN_FOLDER}/../third-party/yq"
    sourceScript "${systemYamlHelper}"
    sourceScript "${installerCommon}"
    sourceScript "${artCommon}"

    export JF_SYSTEM_YAML="${JF_PRODUCT_HOME}/var/etc/system.yaml"
}

# Print on container startup information about Dockerfile location
printDockerFileLocation() {
    logger "Dockerfile for this image can found inside the container."
    logger "To view the Dockerfile: 'cat /docker/artifactory-pro/Dockerfile.artifactory'."
}

terminate () {
    echo -e "\nTerminating Artifactory"
    ${JF_PRODUCT_HOME}/app/bin/artifactory.sh stop
}

# Catch Ctrl+C and other termination signals to try graceful shutdown
trap terminate SIGINT SIGTERM SIGHUP

logger "Preparing to run Artifactory in Docker"
logger "Running as $(id)"

printDockerFileLocation

initHelpers
# Wait for DB
# On slow systems, when working with docker-compose, the DB container might be up,
# but not ready to accept connections when Artifactory is already trying to access it.
waitForDB
[ $? -eq 0 ] || errorExit "Database failed to start in the given time"

# Run Artifactory as JF_ARTIFACTORY_USER user
exec ${JF_PRODUCT_HOME}/app/bin/artifactory.sh &
art_pid=$!

if [ -n "$JF_ARTIFACTORY_PID" ];
then
    mkdir -p $(dirname "$JF_ARTIFACTORY_PID") || \
    errorExit "Could not create dir for $JF_ARTIFACTORY_PID";
fi

echo "${art_pid}" > ${JF_ARTIFACTORY_PID}

wait ${art_pid}