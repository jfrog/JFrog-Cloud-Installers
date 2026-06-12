#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""Generate the Dell catalog manifest.yaml for the JFrog Platform bundle.

For each per-component zip in --blueprints-dir, emit a manifest entry
with id, revision, title, archive path, application_file_name, and
SHA256 checksum, in the order expected by the Dell catalog.

Usage:
  generate_manifest.py --blueprints-dir <path> \
                       --output <manifest.yaml> \
                       --revision <X.Y.Z.W>
"""

import argparse
import hashlib
import os
import sys

import yaml


COMPONENTS = [
    {
        "id": "jfrog_platform_top_level",
        "title": "JFrog Platform Top-Level Blueprint",
        "archive": "blueprints/jfrog_platform_top_level.zip",
        "application_file_name": "blueprint.yaml",
    },
    {
        "id": "jfrog_input_validator",
        "title": "JFrog Platform Input Validator",
        "archive": "blueprints/jfrog_input_validator.zip",
        "application_file_name": "blueprint.yaml",
    },
    {
        "id": "jfrog_stack_verifier",
        "title": "JFrog Platform Stack Verifier",
        "archive": "blueprints/jfrog_stack_verifier.zip",
        "application_file_name": "blueprint.yaml",
    },
    {
        "id": "jfrog_platform_component",
        "title": "JFrog Platform Component",
        "archive": "blueprints/jfrog_platform_component.zip",
        "application_file_name": "blueprint.yaml",
    },
]


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--blueprints-dir", required=True,
                        help="Directory containing the per-component zips")
    parser.add_argument("--output", required=True,
                        help="Path to write manifest.yaml")
    parser.add_argument("--revision", required=True,
                        help="4-part revision string (MAJOR.MINOR.PATCH.BUILD)")
    args = parser.parse_args()

    if not args.revision.count(".") == 3:
        print(
            f"ERROR: --revision must be 4-part MAJOR.MINOR.PATCH.BUILD; "
            f"got {args.revision!r}",
            file=sys.stderr,
        )
        sys.exit(1)

    entries = []
    for comp in COMPONENTS:
        zip_name = os.path.basename(comp["archive"])
        zip_path = os.path.join(args.blueprints_dir, zip_name)
        if not os.path.isfile(zip_path):
            print(f"ERROR: missing zip {zip_path}", file=sys.stderr)
            sys.exit(1)
        entries.append({
            "id": comp["id"],
            "revision": args.revision,
            "title": comp["title"],
            "archive": comp["archive"],
            "application_file_name": comp["application_file_name"],
            "icon": "",
            "signature": "",
            "checksum": f"sha256 {sha256(zip_path)}",
        })

    manifest = {"blueprints": entries}
    with open(args.output, "w") as f:
        yaml.safe_dump(manifest, f, sort_keys=False, default_flow_style=False)

    print(f"Wrote {args.output} with {len(entries)} blueprint(s) at revision {args.revision}")


if __name__ == "__main__":
    main()
