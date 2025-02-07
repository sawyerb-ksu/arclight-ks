#!/bin/bash

if [[ -z "${CI}" ]]; then
    echo "This script is intended to be run in a CI environment."
    exit 1
fi

set -e
set -o pipefail

chart_path="chart/dul-arclight"
chart_name="$(awk '/^name/ {print $2}' ${chart_path}/Chart.yaml)"


helm upgrade ${chart_name} ${chart_path} --install \
    --values ${HELM_CHART_VALUES} \
    --set appImageStreamTag=${CI_COMMIT_SHORT_SHA} \
    "$@"
