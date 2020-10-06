#!/usr/bin/env bash

# install via helm with default postgresql configuration
helm upgrade --install artifactory-ha . \
               --set artifactory-ha.nginx.service.ssloffload=true \
               --set artifactory-ha.nginx.tlsSecretName=tls-ingress \
               --set artifactory-ha.artifactory.node.replicaCount=1 \
               --set artifactory-ha.artifactory.license.secret=artifactory-license,artifactory-ha.artifactory.license.dataKey=artifactory.cluster.license \
               --set artifactory-ha.database.type=postgresql \
               --set artifactory-ha.database.driver=org.postgresql.Driver \
               --set artifactory-ha.database.url=jdbc:postgresql://postgres-postgresql:5432/artifactory \
               --set artifactory-ha.database.user=artifactory \
               --set artifactory-ha.database.password=password \
               --set artifactory-ha.artifactory.joinKey=EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE \
               --set artifactory-ha.artifactory.masterKey=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF \
               --set artifactory-ha.databaseUpgradeReady=true

