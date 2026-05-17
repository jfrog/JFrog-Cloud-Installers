#!/usr/bin/env python3
# Copyright (c) 2026 JFrog Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0.
# See LICENSE file in the project root for full license information.
"""Merge nginx mainConf into sizing templates at build time.

Reads the raw nginx.conf content and inserts it as nginx.mainConf
under the existing artifactory.nginx block in each sizing template.
Source sizing templates are not modified — only staged copies.

Usage: merge_nginx_config.py <nginx-main-conf.txt> <sizing-dir>
"""
import sys
import os
import glob


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <nginx-main-conf.txt> <sizing-dir>", file=sys.stderr)
        sys.exit(1)

    nginx_file = sys.argv[1]
    sizing_dir = sys.argv[2]

    with open(nginx_file) as f:
        nginx_conf = f.read().rstrip()

    if not nginx_conf:
        print(f"ERROR: Empty nginx conf in {nginx_file}", file=sys.stderr)
        sys.exit(1)

    mainconf_block = "    mainConf: |\n"
    for line in nginx_conf.split("\n"):
        mainconf_block += f"      {line}\n"

    for path in sorted(glob.glob(os.path.join(sizing_dir, "platform-*.yaml"))):
        with open(path) as f:
            content = f.read()

        marker = "\n  nginx:\n"
        if marker not in content:
            print(
                f"  WARNING: 'nginx:' block not found in {os.path.basename(path)}",
                file=sys.stderr,
            )
            continue

        idx = content.index(marker) + len(marker)
        content = content[:idx] + mainconf_block + content[idx:]

        with open(path, "w") as f:
            f.write(content)
        print(f"  Merged mainConf into {os.path.basename(path)}")


if __name__ == "__main__":
    main()
