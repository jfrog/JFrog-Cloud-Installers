#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""Resolve the bundled-NGINX LoadBalancer URL into a clean string capability.

The check_nginx_service_endpoint node only has an instance in NGINX/LoadBalancer
mode (default_instances = discover_lb_endpoint, which is 0 in ingress mode). A
capability that reads get_attribute directly from that node therefore renders the
raw, unresolved intrinsic-function JSON in ingress mode (e.g.
{"concat": ["http://", {"get_attribute": [...]}]}). This node always runs, so the
platform_url_loadbalancer capability reads a real string from here instead:
"http://<ip>" when a LoadBalancer IP exists, otherwise "".
"""
from dell import ctx
from dell.state import ctx_parameters as inputs

lb_ip = inputs.get("lb_ip")
# In ingress mode the source node has no instance, so lb_ip may arrive as None
# or as the unresolved get_attribute structure; treat anything that is not a
# plain non-empty string as "no LoadBalancer".
if not isinstance(lb_ip, str) or not lb_ip or lb_ip.startswith("{"):
    lb_ip = ""

url = "http://{}".format(lb_ip) if lb_ip else ""
ctx.instance.runtime_properties["platform_url_loadbalancer"] = url
ctx.logger.info("platform_url_loadbalancer=%r (lb_ip=%r)", url, lb_ip)
