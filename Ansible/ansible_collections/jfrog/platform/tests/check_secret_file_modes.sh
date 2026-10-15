#!/usr/bin/env bash
# Fails if any template/copy task writing system.yaml or rabbitmq.conf is world-readable or has no owner.
# YAML 1.1 decodes an unquoted 0644 as octal; this check accepts both that int and a quoted string.
set -euo pipefail
ROOT="${1:-$(cd "$(dirname "$0")/../roles" && pwd)}"
python3 - "$ROOT" <<'PY'
import pathlib
import sys

bad = []
root = pathlib.Path(sys.argv[1])


def task_blocks(text):
    blocks = []
    current = None
    for line in text.splitlines():
        if line.startswith("- name:"):
            if current is not None:
                blocks.append(current)
            current = [line]
        elif current is not None:
            current.append(line)
    if current:
        blocks.append(current)
    return blocks


def field(block, key):
    prefix = key + ":"
    for line in block:
        stripped = line.strip()
        if stripped.startswith(prefix):
            return stripped.split(":", 1)[1].strip().strip("'\"")
    return None


def mode_value(raw):
    if raw is None:
        return None
    if raw.isdigit():
        return int(raw, 8)
    return None


for path in sorted(root.glob("*/tasks/**/*.yml")):
    for block in task_blocks(path.read_text()):
        body = "\n".join(block)
        if "ansible.builtin.template:" not in body and "ansible.builtin.copy:" not in body and "\ntemplate:" not in body and "\ncopy:" not in body:
            continue
        dest = field(block, "dest") or ""
        if not dest.endswith(("system.yaml", "rabbitmq.conf")):
            continue
        mode = field(block, "mode")
        owner = field(block, "owner")
        value = mode_value(mode)
        if owner is None or value is None or (value & 0o007):
            name = block[0].split(":", 1)[1].strip()
            bad.append(f"{path}: {name} mode={mode} owner={owner}")

print("\n".join(bad))
sys.exit(1 if bad else 0)
PY
