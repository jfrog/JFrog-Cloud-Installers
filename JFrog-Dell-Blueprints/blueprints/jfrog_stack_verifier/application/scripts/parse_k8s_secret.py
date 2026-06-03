#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""Parse the DAP k8s credentials secret into a Kubernetes plugin client_config.

Stores the result on the runtime properties of the calling node so the
Kubernetes plugin can use it via get_attribute.
"""

import json

from dell import ctx
from dell.state import ctx_parameters as inputs
from dell.manager import get_rest_client
from dell.exceptions import NonRecoverableError


def retrieve_k8s_secret(secret_name):
    """
    Retrieves the Kubernetes secret from the dell secrets manager.

    Args:
        secret_name (str): The name of the Kubernetes secret to retrieve.

    Returns:
        dict: The secret's value in dict format.

    Raises:
        NonRecoverableError: If the secret retrieval fails.
    """
    client = get_rest_client()
    try:
        secret_str = client.secrets.get(str(secret_name)).value
        # Check if secret is already a dictionary (new DSPO)
        if isinstance(secret_str, dict):
            return secret_str
        else:
            # Attempt to load secret as JSON to support older DSPO
            secret_value = json.loads(secret_str)
            return secret_value

    except json.JSONDecodeError as e:
        ctx.logger.error(f"Failed to parse secret as JSON: {e}")
        raise NonRecoverableError(f"Secret parsing error: {str(e)}")
    except NonRecoverableError:
        raise
    except Exception as e:
        ctx.logger.error(f"Failed to retrieve Kubernetes secret: {secret_name}. Error: {str(e)}")
        raise NonRecoverableError(f"Failed to retrieve Kubernetes secret: {secret_name}. Error: {str(e)}")


def _prepare_token_config(client_config, secret_response):
    """
    Prepares the token-based authentication configuration for the Kubernetes client.

    Args:
        client_config (dict): The Kubernetes client configuration object.
        secret_response (dict): The secret response containing Kubernetes configuration details.

    Returns:
        dict: The updated Kubernetes client configuration object.
    """
    if "token" in secret_response:
        client_config["token"] = secret_response.get("token")
        ctx.logger.info("Token-based authentication found and added to configuration.")
    else:
        ctx.logger.error("Token not found in secret response.")
        raise NonRecoverableError("Token-based authentication not found in secret response.")

    return client_config


def _prepare_tls_config(client_config, secret_response):
    """
    Prepares the TLS/SSL configuration for the Kubernetes client.

    Args:
        client_config (dict): The Kubernetes client configuration object.
        secret_response (dict): The secret response containing Kubernetes configuration details.

    Returns:
        dict: The updated Kubernetes client configuration object.
    """
    if "ssl_ca_cert" in secret_response:
        client_config["ssl_ca_cert"] = secret_response.get("ssl_ca_cert")
        ctx.logger.info("SSL CA certificate found and added to configuration.")
    else:
        ctx.logger.error("SSL CA certificate not found in secret response.")
        raise NonRecoverableError("SSL CA certificate not found in secret response.")

    if "cert_file" in secret_response:
        client_config["cert_file"] = secret_response.get("cert_file")
    else:
        ctx.logger.error("Certificate file not found in secret response.")
        raise NonRecoverableError("Certificate file not found in secret response.")
    if "key_file" in secret_response:
        client_config["key_file"] = secret_response.get("key_file")
    else:
        ctx.logger.error("Key file not found in secret response.")
        raise NonRecoverableError("Key file not found in secret response.")

    return client_config


def get_k8s_client_config(secret_response):
    """
    Constructs the Kubernetes client configuration based on the provided secret.

    Args:
        secret_response (dict): The secret response containing Kubernetes configuration details.

    Returns:
        dict: A Kubernetes client configuration object.
    """
    client_config = {}

    if "host" in secret_response:
        client_config["host"] = secret_response.get("host")
    else:
        ctx.logger.error("Host not found in secret response.")
        raise NonRecoverableError("Host not found in secret response.")

    if "port" in secret_response:
        client_config["port"] = secret_response.get("port", 6443)
    else:
        ctx.logger.error("Port not found in secret response.")
        raise NonRecoverableError("Port not found in secret response.")

    if "verify_ssl" in secret_response:
        client_config["verify_ssl"] = secret_response.get("verify_ssl")
    else:
        ctx.logger.error("Verify SSL not found in secret response.")
        raise NonRecoverableError("Verify SSL not found in secret response.")

    verify_ssl = client_config.get("verify_ssl")
    if verify_ssl == "TLS":
        client_config = _prepare_tls_config(client_config, secret_response)
    elif verify_ssl == "Token":
        client_config = _prepare_token_config(client_config, secret_response)
    else:
        ctx.logger.error(f"Unsupported verify_ssl value: '{verify_ssl}'. Expected 'TLS' or 'Token'.")
        raise NonRecoverableError(f"Unsupported verify_ssl value: '{verify_ssl}'. Expected 'TLS' or 'Token'.")

    proxy_settings = {}
    proxy_settings["disable"] = False
    proxy_settings["auto_resolve"] = True
    client_config["configuration"] = {
        "proxy_settings": proxy_settings
    }

    return client_config


def main():
    try:
        k8s_secret_name = inputs.get("k8s_credentials")
        if not k8s_secret_name:
            ctx.logger.error("Kubernetes secret name not provided in inputs.")
            raise NonRecoverableError("Missing Kubernetes secret name in inputs.")

        secret_response = retrieve_k8s_secret(k8s_secret_name)
        k8s_client_config = get_k8s_client_config(secret_response)
        ctx.instance.runtime_properties["k8s_client_config"] = k8s_client_config
        ctx.logger.info("k8s client_config built (host=%s)", k8s_client_config.get("host", "<unset>"))

    except NonRecoverableError:
        raise
    except Exception as e:
        ctx.logger.error(f"Unexpected error occurred: {str(e)}")
        raise NonRecoverableError(f"Unexpected error occurred: {str(e)}")


if __name__ == "__main__":
    main()
