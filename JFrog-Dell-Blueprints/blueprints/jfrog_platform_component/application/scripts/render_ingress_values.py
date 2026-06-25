#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""Render the deployer-supplied ingress annotations into a Helm values file.

The ingress_annotations input is a free-form map that can vary per deployment
and may contain values DAP set_values (`helm --set`) cannot carry: bare numbers
("0", "600"), booleans as strings ("false"), and multi-line blocks (the Docker
location-snippets). Helm's documented home for such "complex configs" is a
values file, so this script writes:

    artifactory:
      ingress:
        annotations:
          <key>: <value>

to a stable absolute path and exposes it via the values_file_path runtime
property. The Helm release loads it with a `--values` flag on install/upgrade
only (never uninstall). Values are emitted with json.dumps, which produces valid
YAML scalars (newlines escaped as \\n) without requiring PyYAML on the agent.

The blueprint OWNS the `nginx.org/redirect-to-https` annotation (it is not part
of the deployer default): it is set to "false" only when TLS is disabled so
plain HTTP keeps working, and omitted when TLS is enabled (HTTPS is available),
matching the standard Artifactory ingress configuration.

This script also OWNS the artifactory.ingress.tls list. A static helm --set
always emits a tls[0] entry (with hosts but an empty secretName when TLS is off),
which leaves a stray `tls:` block on the rendered Ingress. So the tls list is
written here ONLY when ingress_tls_enabled is true:

    artifactory:
      ingress:
        tls:
          - secretName: <release>-tls
            hosts:
              - <ingress_host>

When TLS is disabled the tls key is omitted entirely, so the chart default
(empty list) applies and no tls block appears on the Ingress.
"""
import json
import os
import shutil

from dell import ctx
from dell.state import ctx_parameters as inputs

annotations = inputs.get("ingress_annotations") or {}
namespace = inputs.get("namespace") or "default"
release = inputs.get("release_name") or "jfrog-platform"
host = inputs.get("ingress_host") or ""
tls_on = str(inputs.get("ingress_tls_enabled") or "false").lower() == "true"

if not isinstance(annotations, dict):
    annotations = {}
else:
    annotations = dict(annotations)

# redirect-to-https is TLS-state dependent and blueprint-managed: present only
# when TLS is off (forces plain HTTP regardless of any controller-global
# default); omitted when TLS is on.
annotations.pop("nginx.org/redirect-to-https", None)
if not tls_on:
    annotations["nginx.org/redirect-to-https"] = "false"

lines = ["---", "artifactory:", "  ingress:"]
if annotations:
    lines.append("    annotations:")
    for key, value in annotations.items():
        rendered = "" if value is None else str(value)
        lines.append(f"      {json.dumps(str(key))}: {json.dumps(rendered)}")
else:
    lines.append("    annotations: {}")

# Only emit the tls list when TLS is enabled; otherwise leave it unset so the
# chart default applies and no tls block is rendered on the Ingress.
if tls_on:
    lines.append("    tls:")
    lines.append("      - secretName: {}".format(json.dumps(f"{release}-tls")))
    lines.append("        hosts:")
    lines.append(f"          - {json.dumps(host)}")

# Write under the deployment's local workdir (not /tmp) so the values file is
# scoped to this deployment and cleaned up with it. Recreate the jFrog dir each
# run so stale renders never linger.
deployment_dir = ctx.local_deployment_workdir()
jfrog_dir = os.path.join(deployment_dir, "jFrog")
if os.path.exists(jfrog_dir):
    ctx.logger.info("Removing existing directory: %s", jfrog_dir)
    shutil.rmtree(jfrog_dir)
os.makedirs(jfrog_dir, exist_ok=True)

path = os.path.join(
    jfrog_dir, f"jfrog-ingress-values-{namespace}-{release}.yaml"
)
with open(path, "w") as handle:
    handle.write("\n".join(lines) + "\n")

ctx.instance.runtime_properties["values_file_path"] = path
ctx.logger.info(
    "rendered %d ingress annotation(s), ingress_tls_enabled=%s, to %s",
    len(annotations), tls_on, path,
)
