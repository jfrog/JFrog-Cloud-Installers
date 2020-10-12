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

JOIN_KEY=93f1e5d2e8863b3ec14f5cdf136c7896

helm upgrade --install pipelines . \
     --set pipelines.pipelines.jfrogUrl=http://openshiftartifactoryha-nginx \
     --set pipelines.pipelines.jfrogUrlUI=http://openshiftartifactoryha-nginx \
     --set pipelines.pipelines.masterKey=$MASTER_KEY \
     --set pipelines.pipelines.joinKey=$JOIN_KEY \
     --set pipelines.pipelines.accessControlAllowOrigins_0=http://openshiftartifactoryha-nginx \
     --set pipelines.pipelines.accessControlAllowOrigins_1=http://openshiftartifactoryha-nginx \
     --set pipelines.pipelines.msg.uiUser=monitor \
     --set pipelines.pipelines.msg.uiUserPassword=monitor \
     --set pipelines.postgresql.enabled=false \
     --set pipelines.global.postgresql.host=postgres-postgresql \
     --set pipelines.global.postgresql.port=5432 \
     --set pipelines.global.postgresql.database=pipelinesdb \
     --set pipelines.global.postgresql.user=artifactory \
     --set pipelines.global.postgresql.password=password \
     --set pipelines.global.postgresql.ssl=false \
     --set pipelines.rabbitmq.rabbitmq.username=user \
     --set pipelines.rabbitmq.rabbitmq.password=bitnami \
     --set pipelines.rabbitmq.externalUrl=amqps://pipelines-rabbit.jfrog.tech \
     --set pipelines.pipelines.api.externalUrl=http://pipelines-api.jfrog.tech \
     --set pipelines.pipelines.www.externalUrl=http://pipelines-www.jfrog.tech
