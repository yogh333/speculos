#!/bin/bash

set -e

exec docker run \
    -v $(pwd)/apps:/speculos/apps \
    --publish 1234:1234 \
    --publish 1236:1236 \
    --publish 5900:5900 \
    --publish 9999:9999 \
    --publish 40000:40000 \
    --publish 41000:41000 \
    --publish 42000:42000 \
    -it ledgerhq/speculos \
    --display headless --vnc-port 5900 \
    $*
