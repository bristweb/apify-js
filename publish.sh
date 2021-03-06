#!/bin/bash

set -e

RED='\033[0;31m'
NC='\033[0m' # No Color

# Do this BEFORE checking there are no git changes!
echo "Generating documentation ..."
npm run build-docs
npm run build-readme

PACKAGE_NAME=`node -pe "require('./package.json').name"`
PACKAGE_VERSION=`node -pe "require('./package.json').version"`
BRANCH=`git status | grep 'On branch' | cut -d ' ' -f 3`
BRANCH_UP_TO_DATE=`git status | grep 'nothing to commit' | tr -s \n ' '`;
GIT_TAG="v${PACKAGE_VERSION}"

if [ -z "${BRANCH_UP_TO_DATE}" ]; then
    printf "${RED}You have uncommitted changes!${NC}\n"
    exit 1
fi

echo "Pushing to git ..."
git push

# Master gets published as LATEST - the package already needs to be published as BETA.
if [ "${BRANCH}" = "master" ]; then
    EXISTING_NPM_VERSION=$(npm view ${PACKAGE_NAME} versions --json | grep ${PACKAGE_VERSION} | tee) # Using tee to swallow non-zero exit code
    if [ -z "${EXISTING_NPM_VERSION}" ]; then
        printf "${RED}Version ${PACKAGE_VERSION} was not yet published on NPM. Note that you can only publish to NPM from \"develop\" branch!${NC}\n"
        exit 1
    else
        echo "Tagging version ${PACKAGE_VERSION} with tag \"latest\" ..."
        RUNNING_FROM_SCRIPT=1 npm dist-tag add ${PACKAGE_NAME}@${PACKAGE_VERSION} latest
    fi

    # TODO: We should call this automatically, and force user to have the necessary env vars set!
    echo "IMPORTANT: Now publish the new documentation by running website/publish_docs.sh !!!"

# Any other branch gets published as BETA and we don't allow to override tag of existing version.
else
    echo "Publishing version ${PACKAGE_VERSION} with tag \"beta\" ..."
    RUNNING_FROM_SCRIPT=1 npm publish --tag beta

    echo "Tagging git commit with ${GIT_TAG} ..."
    git tag ${GIT_TAG}
    git push origin ${GIT_TAG}
    echo "Git tag: ${GIT_TAG} created."
fi


echo "Done."
