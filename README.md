# ykmicropython

This is an experimental yk-jit-enabled fork of micropython.

Only the UNIX port is supported.

## Building

All build commands are done in `ports/unix`.

As per the [micropython build
instructions](https://github.com/micropython/micropython/tree/master/ports/unix),
first run the initial setup commands:

```
$ apt install build-essential git python3 pkg-config libffi-dev # e.g. for debian
$ make -C ../../mpy-cross
$ make submodules
```

Then to build with yk support, do:

```
PATH=/path/to/yk/bin:$PATH YK_BUILD_TYPE=<debug|release|...> make V=1
```

 (To build with yk debug string support, add
 `CFLAGS_EXTRA="-DYKMP_DEBUG_STRS=1"` at the end of the `make` invocation)

Then the vm executable can be found at `./build-standard/micropython`.

## yk-related tips

 - run `micropython` with `-v -v -v` to see the program's bytecode annotated
   with yk locations.
