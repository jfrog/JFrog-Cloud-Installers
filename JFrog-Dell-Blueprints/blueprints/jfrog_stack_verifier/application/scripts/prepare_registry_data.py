#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""Build a base64-encoded .dockerconfigjson for an image-pull Secret.

When no registry credentials are provided, an empty config is produced
so the Job pulls anonymously from a public registry.
"""

import base64
import json

from dell import ctx
from dell.state import ctx_parameters as inputs


def main():
    registry = inputs.get("container_registry_name") or "docker.io"
    username = inputs.get("container_registry_username") or ""
    password = inputs.get("container_registry_password") or ""

    auths = {}
    if username and password:
        token = base64.b64encode(
            f"{username}:{password}".encode()
        ).decode("utf-8")
        auths[registry] = {
            "username": username,
            "password": password,
            "auth": token,
        }
        ctx.logger.info(
            "Built docker-config for registry %r (user=%s)",
            registry, username,
        )
    else:
        ctx.logger.info(
            "No registry credentials provided -- building empty "
            "docker-config (anonymous pulls only)"
        )

    docker_config = json.dumps({"auths": auths}).encode("utf-8")
    encoded = base64.b64encode(docker_config).decode("utf-8")

    ctx.instance.runtime_properties["registry_secret_data"] = encoded


if __name__ == "__main__":
    main()
