# Build the manager binary
FROM quay.io/operator-framework/helm-operator:v1.0.1
LABEL name="JFrog Pipelines Enterprise Operator" \
      description="Openshift operator to deploy JFrog Pipelines Enterprise based on the Red Hat Universal Base Image." \
      vendor="JFrog" \
      summary="JFrog Pipelines Enterprise Operator" \
      com.jfrog.license_terms="https://jfrog.com/platform/enterprise-plus-eula/"

COPY licenses/ /licenses
ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
WORKDIR ${HOME}
