FROM quay.io/operator-framework/helm-operator:v0.16.0

LABEL name="JFrog Xray Enterprise Operator" \
      description="Openshift operator to deploy JFrog Xray Enterprise based on the Red Hat Universal Base Image." \
      vendor="JFrog" \
      summary="JFrog Xray Enterprise Operator" \
      com.jfrog.license_terms="https://jfrog.com/xray/eula/"

COPY licenses/ /licenses
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts/ ${HOME}/helm-charts/
