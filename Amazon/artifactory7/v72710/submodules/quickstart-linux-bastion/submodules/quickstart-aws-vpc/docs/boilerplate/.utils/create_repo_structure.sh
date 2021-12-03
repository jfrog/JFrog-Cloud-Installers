#!/bin/bash -e
# # Work in progress.
# exit 1

BOILERPLATE_DIR="docs/boilerplate"
GENERATED_DIR="docs/generated"
SPECIFIC_DIR="docs/partner_editable"
# Creating directories.
mkdir -p ${GENERATED_DIR}/parameters
mkdir -p ${GENERATED_DIR}/regions
mkdir -p ${GENERATED_DIR}/services
mkdir -p ${SPECIFIC_DIR}
mkdir -p docs/images
mkdir -p .github/workflows

# Copying content.
rsync -avP ${BOILERPLATE_DIR}/.images/ docs/images/
rsync -avP ${BOILERPLATE_DIR}/.specific/ ${SPECIFIC_DIR}

# enabling workflow.
cp ${BOILERPLATE_DIR}/.actions/main-docs-build.yml .github/workflows/


# creating placeholders.
echo "// placeholder" > ${GENERATED_DIR}/parameters/index.adoc
echo "// placeholder" > ${GENERATED_DIR}/regions/index.adoc
echo "// placeholder" > ${GENERATED_DIR}/services/index.adoc
echo "// placeholder" > ${GENERATED_DIR}/services/metadata.adoc

touch .nojekyll

git add -A docs/
git add .github/
git add .nojekyll
