#!/bin/sh

set -eu

shellcheck .buildbot.sh

cd ports/unix

# First build without the JIT and check the tests still work.
#
# Build instructions for the x86 port:
# https://github.com/micropython/micropython/tree/master/ports/unix
#
# Starting with these initial steps that only have to be done once.
make -j "$(nproc)" -C ../../mpy-cross V=1
make submodules V=1

# Build
make -j"$(nproc)" V=1
set +e
# Test
# FIXME: one of the poll tests is broken, even without yk.
#make -j $(nproc) test V=1
#e=$?
#set -e
#if [ "$e" -ne 0 ]; then
#    make print-failures
#    exit $e
#fi
make clean

# Now test again with the JIT enabled.
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

git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/ykjit/yk
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
cd ..

YK_BUILD_TYPE=release-with-asserts make -j "$(nproc)" V=1
# FIXME: add tests once upstream test has been fixed. See above.

# Check it builds with debug strings.
make clean
YK_BUILD_TYPE=release-with-asserts make -j "$(nproc)" V=1 \
    CFLAGS_EXTRA=-DYKMP_DEBUG_STRS=1
# FIXME: add tests once upstream test has been fixed. See above.
