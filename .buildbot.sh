#!/bin/sh

set -eu

base="$(pwd)"

# Build micropython normally and run its tests
cd ports/unix
make -j "$(nproc)" -C ../../mpy-cross V=1
make submodules V=1
make -j "$(nproc)" test V=1

# Check that a couple of bigger benchmarks run correctly
cd "$base"
git clone --depth=1 --filter=blob:none https://github.com/ykjit/yk-benchmarks/
cd yk-benchmarks/suites/awfy/Python
"$base/ports/unix/build-standard/micropython" harness.py NBody 3 250000 # Fairly quick
"$base/ports/unix/build-standard/micropython" harness.py Richards 3 100 # Somewhat slow
