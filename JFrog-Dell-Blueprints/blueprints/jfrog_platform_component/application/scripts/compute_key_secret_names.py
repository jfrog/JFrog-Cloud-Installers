#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""Resolve effective master/join key Secret names for the JFrog chart.

The master/join key Secrets are only created when their toggle is 1. When
the toggle is 0 the chart must fall back to its own auto-generated keys,
which it does whenever masterKeySecretName / joinKeySecretName is empty.
DAP cannot derive these conditionally in the static set_values list, so we
resolve them here and expose them via runtime properties.
"""
from dell import ctx
from dell.state import ctx_parameters as inputs

create_master = int(inputs.get("create_master_key_secret") or 0)
create_join = int(inputs.get("create_join_key_secret") or 0)

master_name = inputs.get("master_key_secret_name") or ""
join_name = inputs.get("join_key_secret_name") or ""

master_effective = master_name if create_master == 1 else ""
join_effective = join_name if create_join == 1 else ""

ctx.instance.runtime_properties["master_key_secret_name"] = master_effective
ctx.instance.runtime_properties["join_key_secret_name"] = join_effective

ctx.logger.info(
    "masterKeySecretName -> %r (create_master_key_secret=%s)",
    master_effective, create_master,
)
ctx.logger.info(
    "joinKeySecretName -> %r (create_join_key_secret=%s)",
    join_effective, create_join,
)
