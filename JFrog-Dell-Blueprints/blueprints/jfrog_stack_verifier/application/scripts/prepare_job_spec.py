#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""Compute runtime properties for the stack-verification Job.

Generates a unique Job name, resolves the imagePullSecrets list (only when a
private pull secret is configured), and coerces the integer-typed inputs to
strings (Kubernetes requires every container env value to be a string).
All values are exposed via runtime properties for the Job node template.
"""
from dell import ctx
from dell.state import ctx_parameters as inputs
import time
import uuid

ts = int(time.time())
uid = uuid.uuid4().hex[:8]
job_name = f"jfrog-stack-verifier-{ts}-{uid}"
ctx.instance.runtime_properties["job_name"] = job_name
ctx.logger.info("Generated job name: %s", job_name)

create_pull_secret = int(inputs.get("create_pull_secret") or 0)
pull_secret_name = inputs.get("pull_secret_name") or ""
if create_pull_secret == 1 and pull_secret_name:
    image_pull_secrets = [{"name": pull_secret_name}]
    ctx.logger.info(
        "Private registry: Job will use imagePullSecret %r",
        pull_secret_name,
    )
else:
    image_pull_secrets = []
    ctx.logger.info(
        "Public registry: Job will pull anonymously "
        "(no imagePullSecrets)"
    )
ctx.instance.runtime_properties["image_pull_secrets"] = image_pull_secrets

# Kubernetes requires every container env value to be a string;
# coerce the integer-typed inputs so the Job spec is accepted.
ctx.instance.runtime_properties["min_ready_nodes_str"] = str(
    inputs.get("min_ready_nodes", 1)
)
ctx.instance.runtime_properties["db_connect_timeout_str"] = str(
    inputs.get("db_connectivity_timeout_seconds", 10)
)
