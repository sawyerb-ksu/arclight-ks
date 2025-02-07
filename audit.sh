#!/bin/bash

gem install bundler-audit --no-doc

gems="$(bundle-audit check --update --format=json --quiet --no-verbose | jq -r '.results[].gem.name'| sort -u)"

if [[ -n $gems ]]; then
    # Update the gems
    bundle update ${gems}
    # Re-run check
    bundle-audit check
else
    echo "Audit: OK"
fi
