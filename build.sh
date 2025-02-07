#!/bin/bash

set -x

repository="${CI_REGISTRY_IMAGE:-$(basename $(git rev-parse --show-toplevel))}"

build_tag="${build_tag:-${repository}:latest}"

# For older Docker versions
export DOCKER_BUILDKIT="1"

# The builder should be updated whenever the Dockerfile changes
builder_tag="builder-$(cat .dockerignore Dockerfile | md5sum | awk '{print $1}')"
builder="${repository}:${builder_tag}"

# The bundle should be updated whenever the Dockerfile or Gemfile.lock changes
bundle_tag="bundle-$(cat .dockerignore Dockerfile Gemfile.lock | md5sum | awk '{print $1}')"
bundle="${repository}:${bundle_tag}"

git_commit="${CI_COMMIT_SHORT_SHA:-$(git rev-parse --short HEAD)}"

ci_pipeline() {
    [[ -n "${CI}" ]]
}

#
# Image is:
# - not ready if force_build is set
# - ready if it is present locally
# - ready in a CI pipeline if it can be pulled
#
image_is_ready() {
    [[ -n "${force_build}" ]] && return 1
    [[ -n "$(docker images -q $1)" ]] && return 0
    ci_pipeline && docker pull -q $1
}

# Build the builder stage, if necessary
if ! image_is_ready $builder; then
    docker build --pull -t ${builder} --target builder \
	   --build-arg ruby_version=$(cat .ruby-version) .
    ci_pipeline && docker push $builder
fi

# Build the bundle stage, if necessary
if ! image_is_ready $bundle; then
    docker build -t ${bundle} --build-arg builder=${builder} --target bundle .
    ci_pipeline && docker push $bundle
fi

# Build the app
docker build -t ${build_tag} --target app \
       --build-arg builder=${builder} \
       --build-arg bundle=${bundle} \
       --build-arg build_date=$(date -Iseconds) \
       --build-arg git_commit=${git_commit} \
       .
