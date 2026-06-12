# Blueprint Rules Changelog

## Version 1.3 (2026-03-18)

### Added
- **AW-001**: New Mandatory rule — before writing any blueprint, present a plan to the user in natural language (structure, plugins, node types, file count, key decisions). No YAML at this stage.
- **AW-002**: New Mandatory rule — do not begin writing YAML, running `dap-bpa` commands, or creating files until the user explicitly confirms the plan from AW-001.
- **AW-003**: New Mandatory rule — before writing any file to disk, ask the user for the target directory. Never assume the current working directory or any default path.

## Version 1.2 (2026-03-17)

### Changed
- **ND-005**: Added note that scripts executed by the Fabric plugin must be POSIX `sh` compatible — the plugin ignores the shebang and executes via `sh`. This was discovered through production debugging where bash-specific syntax (`< <(...)`, `set -o pipefail`) caused silent parse-time failures with empty stdout/stderr.

## Version 1.1 (2026-03-16)

### Changed
- **ND-002**: Changed from Mandatory to Optional for `update` workflow. Now only mandates `install` and `uninstall` workflows as Mandatory. Additional discuss will take place to see if we can make this rule work more accurately (`update` is a complex logical operation and doesn't always apply to all nodes, but for some it should be mandatory).
- **ND-009**: New Optional rule added recommending nodes implement lifecycle operations for the `update` workflow with full sub-operation guidance (`check_drift`, `preupdate`, `update`, `postupdate`, `update_config`, `update_apply`, `update_postapply`, `preheal`, `heal`, `postheal`).

## Version 1.0 (2026-03-16)

### Added
- Initial release of the blueprint rules document.
