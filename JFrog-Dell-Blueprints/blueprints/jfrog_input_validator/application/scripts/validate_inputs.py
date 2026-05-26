#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""JFrog Platform Input Validator.

Two-phase validation that runs on the central deployment agent before
the stack verifier or any cluster resources are touched:

  Phase 1 - Format checks (regex, enums, ranges) -- instant.
  Phase 2 - Secret store checks (existence, JSON keys, PEM markers).

Failure raises ValueError with a human-readable message and aborts the
deployment.  See docs/input-validator-authoring-guide.md.
"""

import json
import re

from dell import ctx
from dell.state import ctx_parameters as inputs
from dell.manager import get_rest_client


# -- Regex patterns --------------------------------------------------
HTTP_URL_PATTERN = r'^https?://[a-zA-Z0-9._\-]+(:\d+)?(/.*)?$'
DOMAIN_PATTERN = (
    r'^[a-z0-9]([-a-z0-9]*[a-z0-9])?'
    r'(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$'
)
NAMESPACE_PATTERN = r'^[a-z0-9][a-z0-9\-]{0,62}$'
RELEASE_NAME_PATTERN = r'^[a-z0-9][a-z0-9\-]{0,52}$'
K8S_NAME_PATTERN = r'^[a-z0-9][a-z0-9\-]*$'
K8S_QUANTITY_PATTERN = r'^\d+(\.\d+)?(Ei|Pi|Ti|Gi|Mi|Ki|E|P|T|G|M|K)$'
SEMVER_PATTERN = r'^\d+\.\d+\.\d+$'
IPV4_PATTERN = r'^(\d{1,3}\.){3}\d{1,3}$'
PORT_PATTERN = r'^\d{1,5}$'
REGISTRY_PATTERN = r'^[a-zA-Z0-9]([a-zA-Z0-9\-\.:]*[a-zA-Z0-9])?$'
HEX_PATTERN = r'^[0-9a-fA-F]+$'

# Artifactory master/join key length contract, matching the chart's
# default placeholder values in values.yaml (global.masterKey is 64 hex
# chars from `openssl rand -hex 32`; global.joinKey is 32 hex chars
# from `openssl rand -hex 16`).
MASTER_KEY_HEX_LENGTH = 64
JOIN_KEY_HEX_LENGTH = 32

# Sizing tiers that mandate an Artifactory Enterprise license (one per
# replica).  When sizing_template is in this set the validator requires
# create_license_secret == 1 and a non-empty license_secret_ref.
ENTERPRISE_TIERS = ("medium", "large", "xlarge", "2xlarge")
ALL_SIZING_TIERS = ("xsmall", "small") + ENTERPRISE_TIERS


# -- Primitive validators --------------------------------------------
def _require_non_empty_string(value, field_name):
    if not value or not isinstance(value, str):
        raise ValueError(f"{field_name}: must be a non-empty string")


def _validate_pattern(value, field_name, pattern, hint):
    if not re.match(pattern, value):
        raise ValueError(f"{field_name}: {hint} (got: {value!r})")


def _validate_enum(value, field_name, allowed):
    if value not in allowed:
        raise ValueError(
            f"{field_name}: must be one of {allowed}, got: {value!r}"
        )


def _validate_optional_pattern(value, field_name, pattern, hint):
    if value in (None, ""):
        return
    if not isinstance(value, str):
        raise ValueError(f"{field_name}: must be a string")
    _validate_pattern(value, field_name, pattern, hint)


def _validate_optional_quantity(value, field_name):
    if value in (None, ""):
        return
    if not isinstance(value, str):
        raise ValueError(f"{field_name}: must be a string")
    if not re.match(K8S_QUANTITY_PATTERN, value):
        raise ValueError(
            f"{field_name}: invalid Kubernetes quantity "
            f"(expected e.g. 20Gi, 1Ti, 500Mi); got: {value!r}"
        )


def _validate_int_in(value, field_name, allowed):
    if value not in allowed:
        raise ValueError(
            f"{field_name}: must be one of {allowed}, got: {value!r}"
        )


# -- Secret validators -----------------------------------------------
def _parse_secret_value(secret_name, raw):
    """Return a dict if raw is JSON-parseable, else None."""
    if raw is None or raw == "":
        raise ValueError(f"Secret '{secret_name}': value is empty")
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str):
        stripped = raw.strip()
        if not (stripped.startswith("{") and stripped.endswith("}")):
            return None
        try:
            return json.loads(stripped)
        except json.JSONDecodeError:
            return None
    return None


def _get_secret_value(client, secret_name):
    try:
        return client.secrets.get(secret_name).value
    except Exception as exc:
        raise ValueError(
            f"Secret '{secret_name}' not found or inaccessible: {exc}"
        ) from exc


def _validate_secret_keys(client, secret_name, expected_keys):
    raw = _get_secret_value(client, secret_name)
    parsed = _parse_secret_value(secret_name, raw)
    if parsed is None:
        raise ValueError(
            f"Secret '{secret_name}': expected JSON object with keys "
            f"{expected_keys}"
        )
    for key in expected_keys:
        if key not in parsed:
            raise ValueError(
                f"Secret '{secret_name}': missing required key {key!r}"
            )
        if not parsed[key]:
            raise ValueError(
                f"Secret '{secret_name}': empty value for key {key!r}"
            )


def _validate_secret_exists(client, secret_name):
    raw = _get_secret_value(client, secret_name)
    if raw is None or raw == "":
        raise ValueError(f"Secret '{secret_name}': value is empty")


def _validate_secret_hex_length(
    client, secret_name, expected_len, field_name
):
    """Validate that a DAP secret holds a hex string of the exact length
    documented by the jfrog-platform chart's values.yaml (matches
    `openssl rand -hex N` output, which is 2*N lowercase hex chars).
    Whitespace and surrounding quotes are stripped before the check so
    pasted values with trailing newlines still pass.
    """
    raw = _get_secret_value(client, secret_name)
    if not isinstance(raw, str):
        raise ValueError(
            f"Secret '{secret_name}' ({field_name}): expected a string "
            f"value, got {type(raw).__name__}"
        )
    value = raw.strip().strip('"').strip("'")
    if not value:
        raise ValueError(
            f"Secret '{secret_name}' ({field_name}): value is empty"
        )
    if len(value) != expected_len:
        raise ValueError(
            f"Secret '{secret_name}' ({field_name}): expected exactly "
            f"{expected_len} hex characters (matching the chart's "
            f"values.yaml format and `openssl rand -hex "
            f"{expected_len // 2}` output), got {len(value)}"
        )
    if not re.match(HEX_PATTERN, value):
        raise ValueError(
            f"Secret '{secret_name}' ({field_name}): must contain only "
            f"hexadecimal characters [0-9a-fA-F]; generate via "
            f"`openssl rand -hex {expected_len // 2}`"
        )


def _validate_k8s_credentials_secret(client, secret_name):
    """The k8s credentials secret must be a JSON object following Dell's
    DAPO secret format with host, port, verify_ssl, and authentication
    fields based on the verify_ssl type (TLS or Token).
    """
    raw = _get_secret_value(client, secret_name)
    parsed = _parse_secret_value(secret_name, raw)
    if parsed is None:
        raise ValueError(
            f"Secret '{secret_name}': k8s credentials must be a JSON "
            f"object with host/port/verify_ssl fields"
        )
    
    # Required fields for all authentication types
    for key in ("host", "port", "verify_ssl"):
        if key not in parsed:
            raise ValueError(
                f"Secret '{secret_name}': missing required key '{key}'"
            )
    
    verify_ssl = parsed.get("verify_ssl")
    if verify_ssl == "TLS":
        # TLS authentication requires ssl_ca_cert, cert_file, and key_file
        for key in ("ssl_ca_cert", "cert_file", "key_file"):
            if key not in parsed:
                raise ValueError(
                    f"Secret '{secret_name}': missing required key '{key}' "
                    f"for TLS authentication"
                )
    elif verify_ssl == "Token":
        # Token authentication requires ssl_ca_cert and token
        if "token" not in parsed:
            raise ValueError(
                f"Secret '{secret_name}': missing required key 'token' "
                f"for Token authentication"
            )
    else:
        raise ValueError(
            f"Secret '{secret_name}': verify_ssl must be 'TLS' or 'Token', "
            f"got: {verify_ssl!r}"
        )


# -- Phase 1: format checks ------------------------------------------
def _validate_formats():
    ctx.logger.info("Phase 1: validating input formats")

    namespace = inputs.get("namespace") or ""
    _require_non_empty_string(namespace, "namespace")
    _validate_pattern(
        namespace,
        "namespace",
        NAMESPACE_PATTERN,
        "must be a valid Kubernetes namespace name",
    )

    release_name = inputs.get("release_name") or ""
    _require_non_empty_string(release_name, "release_name")
    _validate_pattern(
        release_name,
        "release_name",
        RELEASE_NAME_PATTERN,
        "must be a valid Helm release name",
    )

    chart_version = inputs.get("chart_version") or ""
    _validate_pattern(
        chart_version,
        "chart_version",
        SEMVER_PATTERN,
        "must be a valid semantic version",
    )

    ingress_nginx_version = inputs.get("ingress_nginx_version") or ""
    _validate_pattern(
        ingress_nginx_version,
        "ingress_nginx_version",
        SEMVER_PATTERN,
        "must be a valid semantic version",
    )

    for url_field in ("ingress_nginx_repo_url", "jfrog_helm_repo_url"):
        url_value = inputs.get(url_field) or ""
        _require_non_empty_string(url_value, url_field)
        _validate_pattern(
            url_value, url_field, HTTP_URL_PATTERN,
            "must be a valid HTTP/HTTPS URL",
        )

    registry = inputs.get("container_registry_name") or ""
    _require_non_empty_string(registry, "container_registry_name")
    _validate_pattern(
        registry, "container_registry_name", REGISTRY_PATTERN,
        "must be a valid registry hostname",
    )

    _validate_enum(
        inputs.get("persistence"), "persistence",
        ["storage_type", "storage_class"],
    )
    if inputs.get("persistence") == "storage_class":
        _validate_optional_pattern(
            inputs.get("storage_class"), "storage_class",
            r'^$|^[a-z0-9][a-z0-9\-]*$',
            "must be a valid StorageClass name",
        )
        _validate_optional_quantity(inputs.get("pvc_size"), "pvc_size")
    elif inputs.get("persistence") == "storage_type":
        _validate_enum(
            inputs.get("persistence_type"), "persistence_type",
            ["file-system", "nfs"],
        )
        if inputs.get("persistence_type") == "nfs":
            _validate_optional_pattern(
                inputs.get("nfs_ip"), "nfs_ip", r'^$|' + IPV4_PATTERN,
                "must be empty or a valid IPv4 address",
            )
            _validate_optional_quantity(
                inputs.get("nfs_capacity"), "nfs_capacity"
            )

    _validate_enum(
        inputs.get("postgresql_enabled"), "postgresql_enabled",
        ["true", "false"],
    )
    if inputs.get("postgresql_enabled") == "false":
        _validate_pattern(
            inputs.get("database_host") or "", "database_host",
            r'^[a-zA-Z0-9]([a-zA-Z0-9\-\.]*[a-zA-Z0-9])?$',
            "must be a valid hostname or IP",
        )
        _validate_pattern(
            inputs.get("database_port") or "", "database_port",
            PORT_PATTERN, "must be a numeric port (1-65535)",
        )
        _validate_enum(
            inputs.get("database_ssl_mode"), "database_ssl_mode",
            ["disable", "require", "verify-ca", "verify-full"],
        )
        _validate_int_in(
            int(inputs.get("create_external_db_secret") or 0),
            "create_external_db_secret", [0, 1],
        )

    _validate_enum(
        inputs.get("nginx_enabled"), "nginx_enabled", ["true", "false"]
    )
    if inputs.get("nginx_enabled") == "false":
        _validate_enum(
            inputs.get("ingress_enabled"), "ingress_enabled",
            ["true", "false"],
        )
        if inputs.get("ingress_enabled") == "true":
            _validate_int_in(
                int(inputs.get("install_ingress_controller") or 0),
                "install_ingress_controller", [0, 1],
            )
            ingress_class = inputs.get("ingress_class_name") or ""
            _validate_pattern(
                ingress_class, "ingress_class_name",
                r'^[a-z0-9][a-z0-9\-\.]*$',
                "must be a valid ingress class name",
            )
            ingress_host = inputs.get("ingress_host") or ""
            if ingress_host:
                _validate_pattern(
                    ingress_host, "ingress_host", DOMAIN_PATTERN,
                    "must be a valid DNS hostname",
                )

    _validate_int_in(
        int(inputs.get("create_license_secret") or 0),
        "create_license_secret", [0, 1],
    )
    _validate_int_in(
        int(inputs.get("create_master_key_secret") or 0),
        "create_master_key_secret", [0, 1],
    )
    _validate_int_in(
        int(inputs.get("create_join_key_secret") or 0),
        "create_join_key_secret", [0, 1],
    )

    if int(inputs.get("create_master_key_secret") or 0) == 1 and \
            not inputs.get("master_key_secret_ref"):
        raise ValueError(
            "master_key_secret_ref: must be set when "
            "create_master_key_secret == 1 (provide a DAP general secret "
            "containing the raw Artifactory master key)"
        )
    if int(inputs.get("create_join_key_secret") or 0) == 1 and \
            not inputs.get("join_key_secret_ref"):
        raise ValueError(
            "join_key_secret_ref: must be set when "
            "create_join_key_secret == 1 (provide a DAP general secret "
            "containing the raw Artifactory join key)"
        )

    sizing = inputs.get("sizing_template") or "small"
    _validate_enum(sizing, "sizing_template", list(ALL_SIZING_TIERS))
    if sizing in ENTERPRISE_TIERS:
        if int(inputs.get("create_license_secret") or 0) != 1:
            raise ValueError(
                f"create_license_secret: must be 1 when sizing_template "
                f"is '{sizing}' (Enterprise license required for medium "
                f"and above; one Enterprise license per replica)"
            )
        if not inputs.get("license_secret_ref"):
            raise ValueError(
                f"license_secret_ref: must be set when sizing_template "
                f"is '{sizing}' (provide a DAP general secret containing "
                f"the raw Artifactory license text)"
            )


# -- Phase 2: secret store checks -----------------------------------
def _validate_secrets():
    ctx.logger.info("Phase 2: validating DAP secrets")
    client = get_rest_client()

    expected_basic_auth_keys = inputs.get(
        "expected_basic_auth_keys"
    ) or ["username", "password"]

    _validate_k8s_credentials_secret(client, inputs["k8s_credentials"])

    target_dep_id = inputs.get("target_deployment_id")
    if not target_dep_id:
        raise ValueError(
            "target_deployment_id: must be set to the target "
            "infrastructure deployment ID"
        )
    try:
        client.deployments.get(target_dep_id)
    except Exception as exc:
        raise ValueError(
            f"target_deployment_id: deployment '{target_dep_id}' "
            f"not found or inaccessible: {exc}"
        ) from exc

    registry_creds = inputs.get("container_registry_credentials_secret")
    if registry_creds:
        _validate_secret_keys(
            client, registry_creds, expected_basic_auth_keys
        )

    if inputs.get("postgresql_enabled") == "false":
        _validate_secret_exists(
            client, inputs["database_admin_password"]
        )
        _validate_secret_keys(
            client, inputs["database_credentials"],
            expected_basic_auth_keys,
        )

    if int(inputs.get("create_license_secret") or 0) == 1:
        license_ref = inputs.get("license_secret_ref")
        if not license_ref:
            raise ValueError(
                "license_secret_ref: required when "
                "create_license_secret == 1"
            )
        _validate_secret_exists(client, license_ref)

    if int(inputs.get("create_master_key_secret") or 0) == 1:
        master_key_ref = inputs.get("master_key_secret_ref")
        if not master_key_ref:
            raise ValueError(
                "master_key_secret_ref: required when "
                "create_master_key_secret == 1"
            )
        _validate_secret_hex_length(
            client, master_key_ref, MASTER_KEY_HEX_LENGTH,
            "master_key_secret_ref",
        )

    if int(inputs.get("create_join_key_secret") or 0) == 1:
        join_key_ref = inputs.get("join_key_secret_ref")
        if not join_key_ref:
            raise ValueError(
                "join_key_secret_ref: required when "
                "create_join_key_secret == 1"
            )
        _validate_secret_hex_length(
            client, join_key_ref, JOIN_KEY_HEX_LENGTH,
            "join_key_secret_ref",
        )


def main():
    ctx.logger.info("Starting JFrog Platform input validation")
    _validate_formats()
    _validate_secrets()
    ctx.logger.info("All input validations passed successfully")


if __name__ == "__main__":
    main()
