SHELL := /bin/bash

# --- Bundle naming ---
ZIP_NAME              := jfrog-platform
VERSION               ?= local
CHART_VERSION         ?=
ZIP_OUTPUT_DIR        := target

# Dell catalog revisions are 4-part (MAJOR.MINOR.PATCH.BUILD).  When
# VERSION is "local" or non-semver we fall back to 0.0.0.0 so the
# manifest validator does not reject the build.
REVISION              := $(shell \
    v="$(VERSION)"; v=$$(printf '%s' "$$v" | sed 's/^v//'); \
    if [[ "$$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+$$ ]]; then echo "$$v.0"; \
    elif [[ "$$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$$ ]]; then echo "$$v"; \
    else echo "0.0.0.0"; fi)

# --- Component blueprint directories ---
TOP_LEVEL_DIR         := blueprints/jfrog_platform_top_level
JFROG_COMPONENT_DIR   := blueprints/jfrog_platform_component
INPUT_VALIDATOR_DIR   := blueprints/jfrog_input_validator
STACK_VERIFIER_DIR    := blueprints/jfrog_stack_verifier

# --- Bundle staging ---
BUNDLE_NAME           := $(ZIP_NAME)
BUNDLE_STAGING_DIR    := $(ZIP_OUTPUT_DIR)/.$(BUNDLE_NAME)
BLUEPRINTS_DIR        := $(BUNDLE_STAGING_DIR)/blueprints
PLUGINS_DIR           := $(BUNDLE_STAGING_DIR)/plugins
MANIFEST_FILE         := $(BUNDLE_STAGING_DIR)/manifest.yaml

ZIP_EXCLUDES          := '*/tests/*' '*.test*'

# --- Sync Artifacts from Helm Chart ---
sync_sizing:
ifneq ($(strip $(CHART_VERSION)),)
	./scripts/sync_sizing_templates.sh "$(CHART_VERSION)"
else
	./scripts/sync_sizing_templates.sh
endif
	@mkdir -p "$(JFROG_COMPONENT_DIR)/sizing"
	@cp -R target/sizing/. "$(JFROG_COMPONENT_DIR)/sizing/"

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
	$(eval RESOLVED_CHART_VERSION := $(shell v=$$(./scripts/get_latest_jfrog_platform_version.sh 2>/dev/null); echo "$$v" | grep -oEm1 '[0-9]+\.[0-9]+\.[0-9]+'))
endif
	@if [ -z "$(RESOLVED_CHART_VERSION)" ]; then \
		echo "Error: Unable to resolve Helm chart version." >&2; \
		exit 1; \
	fi
	@echo "Chart version: $(RESOLVED_CHART_VERSION)"

# --- Helpers ---
# Stage one component blueprint directory at the given path,
# copying every file under it except tests.
define stage_component
	@rm -rf "$(2)"
	@mkdir -p "$(2)"
	cp -R "$(1)/." "$(2)/"
endef

# --- Per-component zips ---
# prepare_staging clears the staging directory and creates the bundle
# layout.  Marked phony but only triggered once per invocation thanks
# to .NOTPARALLEL ordering below.
prepare_staging:
	@rm -rf "$(BUNDLE_STAGING_DIR)"
	@mkdir -p "$(BLUEPRINTS_DIR)" "$(PLUGINS_DIR)" "$(BUNDLE_STAGING_DIR)/.stage"

zip_top_level: resolve_chart_version
	$(call stage_component,$(TOP_LEVEL_DIR),$(BUNDLE_STAGING_DIR)/.stage/jfrog_platform_top_level)
	perl -0pi -e "s/default:\s*0\.0\.0/default: $(RESOLVED_CHART_VERSION)/" \
		"$(BUNDLE_STAGING_DIR)/.stage/jfrog_platform_top_level/top_level/inputs_hidden.yaml"
	# Pin the child component revision_id defaults to this build's revision so
	# the top-level wires every ServiceComponent to blueprints registered from
	# the same bundle (otherwise a version bump leaves children stale at 1.0.0.0).
	perl -0pi -e 's/default:\s*"1\.0\.0\.0"/default: "$(REVISION)"/g' \
		"$(BUNDLE_STAGING_DIR)/.stage/jfrog_platform_top_level/top_level/inputs_hidden.yaml"
	cd "$(BUNDLE_STAGING_DIR)/.stage" && zip -rq "$(CURDIR)/$(BLUEPRINTS_DIR)/jfrog_platform_top_level.zip" \
		jfrog_platform_top_level -x $(ZIP_EXCLUDES)
	@rm -rf "$(BUNDLE_STAGING_DIR)/.stage/jfrog_platform_top_level"

zip_jfrog_component: sync resolve_chart_version
	$(call stage_component,$(JFROG_COMPONENT_DIR),$(BUNDLE_STAGING_DIR)/.stage/jfrog_platform_component)
	@mkdir -p "$(BUNDLE_STAGING_DIR)/.stage/jfrog_platform_component/sizing"
	cp -R target/sizing/. "$(BUNDLE_STAGING_DIR)/.stage/jfrog_platform_component/sizing/"
	perl -0pi -e "s/default:\s*0\.0\.0/default: $(RESOLVED_CHART_VERSION)/" \
		"$(BUNDLE_STAGING_DIR)/.stage/jfrog_platform_component/inputs/inputs_hidden.yaml"
	@echo "Merging nginx mainConf into sizing templates..."
	@python3 scripts/merge_nginx_config.py \
		build/nginx-main-conf.txt \
		"$(BUNDLE_STAGING_DIR)/.stage/jfrog_platform_component/sizing"
	cd "$(BUNDLE_STAGING_DIR)/.stage" && zip -rq "$(CURDIR)/$(BLUEPRINTS_DIR)/jfrog_platform_component.zip" \
		jfrog_platform_component -x $(ZIP_EXCLUDES)
	@rm -rf "$(BUNDLE_STAGING_DIR)/.stage/jfrog_platform_component"

zip_input_validator: resolve_chart_version
	$(call stage_component,$(INPUT_VALIDATOR_DIR),$(BUNDLE_STAGING_DIR)/.stage/jfrog_input_validator)
	perl -0pi -e "s/default:\s*0\.0\.0/default: $(RESOLVED_CHART_VERSION)/" \
		"$(BUNDLE_STAGING_DIR)/.stage/jfrog_input_validator/inputs/inputs_hidden.yaml"
	cd "$(BUNDLE_STAGING_DIR)/.stage" && zip -rq "$(CURDIR)/$(BLUEPRINTS_DIR)/jfrog_input_validator.zip" \
		jfrog_input_validator -x $(ZIP_EXCLUDES)
	@rm -rf "$(BUNDLE_STAGING_DIR)/.stage/jfrog_input_validator"

zip_stack_verifier:
	$(call stage_component,$(STACK_VERIFIER_DIR),$(BUNDLE_STAGING_DIR)/.stage/jfrog_stack_verifier)
	cd "$(BUNDLE_STAGING_DIR)/.stage" && zip -rq "$(CURDIR)/$(BLUEPRINTS_DIR)/jfrog_stack_verifier.zip" \
		jfrog_stack_verifier -x $(ZIP_EXCLUDES)
	@rm -rf "$(BUNDLE_STAGING_DIR)/.stage/jfrog_stack_verifier"

zip_components: prepare_staging zip_top_level zip_jfrog_component zip_input_validator zip_stack_verifier

# --- Manifest ---
manifest: zip_components
	@python3 scripts/generate_manifest.py \
		--blueprints-dir "$(BLUEPRINTS_DIR)" \
		--output "$(MANIFEST_FILE)" \
		--revision "$(REVISION)"

# --- Bundle ---
bundle: manifest
	cd "$(BUNDLE_STAGING_DIR)" && zip -rq "$(CURDIR)/$(ZIP_OUTPUT_DIR)/$(BUNDLE_NAME).zip" \
		blueprints plugins manifest.yaml
	@rm -rf "$(BUNDLE_STAGING_DIR)"
	@echo "Done: $(ZIP_OUTPUT_DIR)/$(BUNDLE_NAME).zip"

# --- Validate ---
validate:
	./scripts/validate_blueprints.sh

# --- Clean ---
clean:
	rm -rf target/ build/

# --- Full Build ---
all: bundle

.PHONY: sync sync_sizing sync_nginx_conf resolve_chart_version \
        prepare_staging zip_top_level zip_jfrog_component \
        zip_input_validator zip_stack_verifier \
        zip_components manifest bundle validate clean all
