# yk_path: path to a yk containing `bin`
yk_path := ""
# yk_build_type: debug, release, or release-asserts
yk_build_type := "release"

# List available commands.
default:
    @just --list

# Build ports/unix with the given yk toolchain on PATH.
# Example: just yk_path=/path/to/yk yk_build_type=release build
build:
    PATH="{{yk_path}}/bin:$PATH" YK_BUILD_TYPE={{yk_build_type}} make -C ports/unix -j $(nproc) V=1

# Remove build artifacts.
clean:
    rm -rf ports/unix/build-*
    rm -rf mpy-cross/build
