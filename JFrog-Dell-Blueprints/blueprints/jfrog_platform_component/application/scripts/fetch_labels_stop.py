#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""No-op stop operation for the fetch_labels node.

fetch_labels only updates this deployment's own labels during start; there is
nothing to revert on uninstall, so stop is intentionally a no-op kept for
lifecycle completeness.
"""
from dell import ctx

ctx.logger.info("fetch_labels stop: no label cleanup required on uninstall.")
