#!/bin/bash
code=1
if ./.docker/test.sh -f docker-compose.test-a11y.yml up --exit-code-from app; then
    code=0
fi
./.docker/test.sh down
exit $code
