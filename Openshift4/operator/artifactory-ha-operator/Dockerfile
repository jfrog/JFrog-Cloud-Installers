# Build the manager binary

FROM quay.io/operator-framework/helm-operator:v1.3.0
LABEL name="JFrog Artifactory Enterprise Operator" \
      description="Openshift operator to deploy JFrog Artifactory Enterprise based on the Red Hat Universal Base Image." \
      vendor="JFrog" \
      summary="JFrog Artifactory Enterprise Operator" \
      com.jfrog.license_terms="https://jfrog.com/artifactory/eula/"

COPY  licenses/ /licenses
ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
WORKDIR ${HOME}


