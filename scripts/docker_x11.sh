#!/bin/bash

set -e

exec docker run \
    -e XAUTHORITY="$XAUTHORITY" \
    -e DISPLAY="$DISPLAY" \
    --entrypoint /bin/bash \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $(pwd)/apps:/speculos/apps \
    -v "$XAUTHORITY:$XAUTHORITY" \
    --publish 1234:1234 \
    --publish 1236:1236 \
    --publish 9999:9999 \
    --publish 40000:40000 \
    --publish 41000:41000 \
    --publish 42000:42000 \
    -it speculos-x11 \
    $*
