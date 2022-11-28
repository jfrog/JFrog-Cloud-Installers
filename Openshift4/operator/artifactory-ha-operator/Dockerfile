# Build the manager binary

FROM quay.io/operator-framework/helm-operator:v1.25
LABEL name="JFrog Artifactory Enterprise Operator" \
      description="Openshift operator to deploy JFrog Artifactory Enterprise based on the Red Hat Universal Base Image." \
      vendor="JFrog" \
      summary="JFrog Artifactory Enterprise Operator" \
      com.jfrog.license_terms="https://jfrog.com/artifactory/eula/"

# Adding security checks for container vulnerability scan

USER root

RUN microdnf install yum \
      && yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical \
      && yum clean all \
      && microdnf clean all \
      && microdnf install gnutls \
      && microdnf install nettle  \
      && microdnf update openssl-libs 

RUN microdnf install sudo 
RUN sudo -u helm bash

USER helm


COPY  licenses/ /licenses
ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
WORKDIR ${HOME}


