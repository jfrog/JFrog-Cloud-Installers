SHELL := /bin/bash

# --- Paths ---
BLUEPRINT_NAME        := jfrog-platform
BLUEPRINT_DIR         := blueprints/$(BLUEPRINT_NAME)
ZIP_NAME              := jfrog-dell
VERSION               ?= local
CHART_VERSION         ?=
ZIP_OUTPUT_DIR        := target
ZIP_EXCLUDES          := '*/tests/*' '*.test*'

PACKAGE_ROOT          := $(ZIP_NAME)-$(VERSION)
STAGING_DIR           := $(ZIP_OUTPUT_DIR)/.$(PACKAGE_ROOT)

# --- Sync Artifacts from Helm Chart ---
sync_sizing:
ifneq ($(strip $(CHART_VERSION)),)
	./scripts/sync_sizing_templates.sh "$(CHART_VERSION)"
else
	./scripts/sync_sizing_templates.sh
endif

sync_nginx_conf:
ifneq ($(strip $(CHART_VERSION)),)
	./scripts/sync_networking_modes.sh "$(CHART_VERSION)"
else
	./scripts/sync_networking_modes.sh
endif

sync: sync_sizing sync_nginx_conf

# --- Resolve Chart Version ---
resolve_chart_version:
ifneq ($(strip $(CHART_VERSION)),)
	$(eval RESOLVED_CHART_VERSION := $(CHART_VERSION))
else
	$(eval RESOLVED_CHART_VERSION := $(shell ./scripts/get_latest_jfrog_platform_version.sh | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1))
endif
	@if [ -z "$(RESOLVED_CHART_VERSION)" ]; then \
		echo "Error: Unable to resolve Helm chart version." >&2; \
		exit 1; \
	fi
	@echo "Chart version: $(RESOLVED_CHART_VERSION)"

# --- Blueprint Zipping ---
zip_blueprint: sync resolve_chart_version
	@rm -rf "$(STAGING_DIR)"
	@mkdir -p "$(STAGING_DIR)/$(PACKAGE_ROOT)"
	cp "$(BLUEPRINT_DIR)/blueprint.yaml"  "$(STAGING_DIR)/$(PACKAGE_ROOT)/blueprint.yaml"
	cp "$(BLUEPRINT_DIR)/CHANGELOG.yaml"  "$(STAGING_DIR)/$(PACKAGE_ROOT)/CHANGELOG.yaml"
	cp -R "$(BLUEPRINT_DIR)/top_level"    "$(STAGING_DIR)/$(PACKAGE_ROOT)/top_level"
	cp -R "$(BLUEPRINT_DIR)/application"  "$(STAGING_DIR)/$(PACKAGE_ROOT)/application"
	cp -R target/sizing                   "$(STAGING_DIR)/$(PACKAGE_ROOT)/sizing"
	perl -0pi -e "s/default:\s*0\.0\.0/default: $(RESOLVED_CHART_VERSION)/" \
		"$(STAGING_DIR)/$(PACKAGE_ROOT)/top_level/inputs_hidden.yaml"
	@echo "Merging nginx mainConf into sizing templates..."
	@python3 scripts/merge_nginx_config.py \
		build/nginx-main-conf.txt \
		"$(STAGING_DIR)/$(PACKAGE_ROOT)/sizing"
	cd "$(STAGING_DIR)" && zip -r "$(CURDIR)/$(ZIP_OUTPUT_DIR)/$(ZIP_NAME)-$(VERSION).zip" \
		"$(PACKAGE_ROOT)" -x $(ZIP_EXCLUDES)
	@rm -rf "$(STAGING_DIR)"
	@echo "Done: $(ZIP_OUTPUT_DIR)/$(ZIP_NAME)-$(VERSION).zip"

# --- Validate ---
validate:
	./scripts/validate_blueprints.sh

# --- Clean ---
clean:
	rm -rf target/ build/

# --- Full Build ---
all: zip_blueprint

.PHONY: sync sync_sizing sync_nginx_conf resolve_chart_version \
        zip_blueprint validate clean all
