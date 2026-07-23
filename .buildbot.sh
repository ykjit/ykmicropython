#!/bin/sh

set -eu

base="$(pwd)"

# Build micropython normally and run its tests
cd "$base/ports/unix"
make -j "$(nproc)" -C ../../mpy-cross V=1
make submodules V=1
ulimit -n 1024 # Some micropython tests open lots of files
make -j "$(nproc)" test V=1

cd "$base"
export CARGO_HOME="$PWD/.cargo"
export RUSTUP_HOME="$PWD/.rustup"
export RUSTUP_INIT_SKIP_PATH_CHECK="yes"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh
sh rustup.sh --default-host x86_64-unknown-linux-gnu \
    --default-toolchain nightly \
    --no-modify-path \
    --profile minimal \
    -y
export PATH="$PWD/.cargo/bin/:$PATH"

git clone --depth 1 --filter=blob:none --recurse-submodules --shallow-submodules https://github.com/ykjit/yk
cd yk
echo "yk commit: $(git show -s --format=%H)"
cat << EOF >> Cargo.toml
[profile.release-with-asserts]
inherits = "release"
debug-assertions = true
overflow-checks = true
EOF

cd ykllvm
ykllvm_hash=$(git rev-parse HEAD)
if [ -f /opt/ykllvm_cache/ykllvm-release-with-assertions-"${ykllvm_hash}".tgz ]; then
    mkdir inst
    cd inst
    tar xfz /opt/ykllvm_cache/ykllvm-release-with-assertions-"${ykllvm_hash}".tgz
    cd ..
    # Minimally check that we can at least run `clang --version`: if we can't,
    # we assume the cached binary is too old (e.g. linking against old shared
    # objects) and that we should build our own version.
    if inst/bin/clang --version > /dev/null; then
        YKB_YKLLVM_BIN_DIR="$(pwd)/inst/bin"
        export YKB_YKLLVM_BIN_DIR
    else
        echo "Warning: cached ykllvm not runnable; building from scratch" > /dev/stderr
        rm -rf inst
    fi
fi
cd ..
YKB_YKLLVM_BUILD_ARGS="define:CMAKE_C_COMPILER=/usr/bin/clang,define:CMAKE_CXX_COMPILER=/usr/bin/clang++" \
    cargo build --profile release-with-asserts
export PATH="$PWD/bin:${PATH}"

# Build ykmicropython and run its tests
cd "$base/ports/unix"
rm -rf build-standard
YK_BUILD_TYPE=release-with-asserts make -j "$(nproc)" -C ../../mpy-cross V=1
YK_BUILD_TYPE=release-with-asserts make submodules V=1
YKD_SERIALISE_COMPILATION=1 YK_BUILD_TYPE=release-with-asserts make -j "$(nproc)" test V=1

# Check that a couple of bigger benchmarks run correctly
cd "$base"
git clone --depth=1 --filter=blob:none https://github.com/ykjit/yk-benchmarks/
cd "$base/yk-benchmarks/suites/awfy/Python"
"$base/ports/unix/build-standard/micropython" harness.py NBody 3 250000 # Fairly quick
"$base/ports/unix/build-standard/micropython" harness.py Richards 3 100 # Somewhat slow
