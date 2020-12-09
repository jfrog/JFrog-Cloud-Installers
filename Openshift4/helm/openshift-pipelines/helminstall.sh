#!/usr/bin/env bash

echo "Installing Pipelines"

if [ -z "$MASTER_KEY" ]
then
  MASTER_KEY=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
fi

if [ -z "$JOIN_KEY" ]
then
  JOIN_KEY=EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
fi

helm upgrade --install pipelines . \
     --set pipelines.pipelines.jfrogUrl=http://openshiftartifactoryha-artifactory-ha-primary:8082 \
     --set pipelines.pipelines.jfrogUrlUI=https://johnp.jfrog.tech \
     --set pipelines.pipelines.masterKey=$MASTER_KEY \
     --set pipelines.pipelines.joinKey=$JOIN_KEY \
     --set pipelines.pipelines.accessControlAllowOrigins_0=https://johnp.jfrog.tech \
     --set pipelines.pipelines.accessControlAllowOrigins_1=https://johnp.jfrog.tech \
     --set pipelines.pipelines.msg.uiUser=monitor \
     --set pipelines.pipelines.msg.uiUserPassword=monitor \
     --set pipelines.postgresql.enabled=false \
     --set pipelines.global.postgresql.host=postgres-postgresql \
     --set pipelines.global.postgresql.port=5432 \
     --set pipelines.global.postgresql.database=pipelinedb \
     --set pipelines.global.postgresql.user=artifactory \
     --set pipelines.global.postgresql.password=password \
     --set pipelines.global.postgresql.ssl=false \
     --set pipelines.rabbitmq.rabbitmq.username=user \
     --set pipelines.rabbitmq.rabbitmq.password=bitnami \
     --set pipelines.rabbitmq.externalUrl=amqp://pipelines-rabbit.jfrog.tech \
     --set pipelines.pipelines.api.externalUrl=http://pipelines-api.jfrog.tech:30000 \
     --set pipelines.pipelines.www.externalUrl=http://pipelines-www.jfrog.tech:30001
