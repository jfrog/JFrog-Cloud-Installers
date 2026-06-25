#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""Resolve effective Ingress TLS settings for the JFrog Platform chart.

The chart's artifactory.ingress.tls list (secretName + hosts) is owned by
render_ingress_values.py, which writes it to a values file ONLY when TLS is
enabled (so no stray tls block appears when TLS is off). This node resolves the
remaining TLS-derived values consumed elsewhere in the blueprint:

  * tls_secret_name_effective - the kubernetes.io/tls Secret name when TLS is
    enabled (used as the ingress_tls_secret node's metadata.name); empty when
    disabled. The Secret node is itself gated by create_ingress_tls_secret, so nothing is
    created when off.
  * url_scheme - feeds the platform_url_ingress capability.
  * platform_url_ingress - the Artifactory Ingress base URL (scheme://host), but ONLY when
    Ingress mode is enabled. In bundled-NGINX (LoadBalancer) mode it is "" so the
    platform_url_ingress capability stays empty and only platform_url_loadbalancer
    carries a value (and vice versa). This is the conditional-display mechanism:
    capabilities always render in the DAP UI, so the inactive mode shows an empty
    string instead of a misleading URL.
"""
from dell import ctx
from dell.state import ctx_parameters as inputs

tls_on = str(inputs.get("ingress_tls_enabled") or "false").lower() == "true"
ingress_on = str(inputs.get("ingress_enabled") or "false").lower() == "true"
release = inputs.get("release_name") or "jfrog-platform"
host = inputs.get("ingress_host") or ""
secret_name = f"{release}-tls"
scheme = "https" if tls_on else "http"
ctx.instance.runtime_properties["tls_secret_name_effective"] = secret_name if tls_on else ""
ctx.instance.runtime_properties["url_scheme"] = scheme
# Conditional: only populated in Ingress mode; empty in LoadBalancer mode so the
# two URL capabilities are mutually exclusive.
ingress_url = f"{scheme}://{host}" if (ingress_on and host) else ""
ctx.instance.runtime_properties["platform_url_ingress"] = ingress_url
ctx.logger.info(
    "ingress TLS enabled=%s ingress_enabled=%s host=%r secretName=%r url=%r",
    tls_on, ingress_on, host, secret_name if tls_on else "", ingress_url,
)
