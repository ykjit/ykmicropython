#!/bin/sh

set -eu

cd ports/unix

# Build micropython normally and run its tests
make -j "$(nproc)" -C ../../mpy-cross V=1
make submodules V=1
make -j "$(nproc)" test V=1
