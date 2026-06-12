#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""Link this deployment to its target Kubernetes infrastructure.

Runs on the manager (central_deployment_agent). Reads target_deployment_id
from this deployment's inputs, fetches the target deployment's labels, and
appends the target_id label so the JFrog Platform deployment is linked to
its target infrastructure for SaaS DAPO.
"""
from dell import ctx
from dell.manager import get_rest_client

client = get_rest_client()
this_dep = client.deployments.get(ctx.deployment.id)
target_dep = client.deployments.get(this_dep.inputs["target_deployment_id"])
labels = []
ctx.logger.info("current labels: {}".format(this_dep.labels))
for label in this_dep.labels:
    labels.append({label.key: label.value})
ctx.logger.info("target_dep labels: {}".format(target_dep.labels))
labels.append({"target_id": [label.value for label in target_dep.labels if label.get("key") == "target_id"][0]})

ctx.logger.info("updating labels to: {}".format(labels))
client.deployments.update_labels(ctx.deployment.id, labels)
