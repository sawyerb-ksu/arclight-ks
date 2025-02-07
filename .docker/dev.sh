#!/bin/bash

cd "$(dirname ${BASH_SOURCE[0]})"

rm -f ../tmp/pids/server.pid

compose_opts="-f docker-compose.yml -f docker-compose.dev.yml -p dul-arclight-dev"

if [[ "$1" =~ up ]]; then
    trap "docker compose ${compose_opts} down" SIGINT
fi

docker compose ${compose_opts} "$@"
