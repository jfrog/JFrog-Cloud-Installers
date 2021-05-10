ARG UPSTREAM_IMAGE=docker.bintray.io/jfrog/artifactory-pro
ARG UPSTREAM_TAG
FROM ${UPSTREAM_IMAGE}:${UPSTREAM_TAG}
USER root
# Copy security.xml
COPY ./security.xml /security_bootstrap/security.import.xml
RUN chown -R artifactory:artifactory /security_bootstrap
# Copy entrypoint script.
COPY ./entrypoint-artifactory.sh /entrypoint-artifactory.sh
COPY ./installer-info.json /artifactory_bootstrap/info/installer-info.json
RUN chmod 755 /entrypoint-artifactory.sh
USER artifactory
