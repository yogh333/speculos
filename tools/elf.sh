#!/bin/bash

# https://obrunet.github.io/pythonic%20ideas/compilation_cython/
# sudo apt install cython3

set -e

cython -3 speculos.py --embed

xxd -i build/src/launcher /tmp/launcher.h
xxd -i build/vnc/vnc_server /tmp/vnc_server.h
gcc -I /tmp/ -c -o /tmp/embbed_resources.o tools/embbed_resources.c

cc speculos.c -o speculos $(pkg-config --libs --cflags python3) /tmp/embbed_resources.o
