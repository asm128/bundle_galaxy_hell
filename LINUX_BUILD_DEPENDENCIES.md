# Galaxy Hell Linux/XCB build dependencies

This record describes the currently verified Linux/XCB software-rendering build. It does not describe the deferred OpenGL, XI2 multi-keyboard, or input-method work.

## Direct build dependencies

The build uses GNU Make, `g++` with C++23 support, and `ar`. On Debian/Ubuntu systems the complete direct package set is:

```sh
sudo apt-get install build-essential libxcb1-dev libxcb-image0-dev libxkbcommon-dev libxkbcommon-x11-dev
```

The platform libraries correspond directly to the host link line:

| Makefile library | Development package | Purpose |
| --- | --- | --- |
| `xcb` | `libxcb1-dev` | XCB connection, window, and core input APIs |
| `xcb-image` | `libxcb-image0-dev` | XCB software-image presentation |
| `xkbcommon` | `libxkbcommon-dev` | XKB keymap, modifier, keysym, Unicode, and compose state |
| `xkbcommon-x11` | `libxkbcommon-x11-dev` | Creation of XKB state from the XCB/X11 core keyboard |
| `pthread` | provided by the system C library development files in `build-essential` | Thread support |

`gpk/llc/Makefile` includes `../../zlib`. That is the source bundled in this checkout; the verified build does not require the system `zlib1g-dev` package and does not link `-lz`.

Installing `libxkbcommon-x11-dev` also installs its XKB/XCB development dependency (`libxcb-xkb-dev`). It is transitive and does not need to be listed separately in the direct install command.

## Runtime dependencies

The current `Linux.x64.Debug/galaxy_hell.bin` was inspected with `ldd`. Its shared-library closure is:

| Shared library | Debian/Ubuntu runtime package |
| --- | --- |
| `libxcb.so.1` | `libxcb1` |
| `libxcb-image.so.0` | `libxcb-image0` |
| `libxkbcommon.so.0` | `libxkbcommon0` |
| `libxkbcommon-x11.so.0` | `libxkbcommon-x11-0` |
| `libxcb-xkb.so.1` | `libxcb-xkb1` |
| `libxcb-shm.so.0` | `libxcb-shm0` |
| `libxcb-util.so.1` | `libxcb-util1` |
| `libXau.so.6` | `libxau6` |
| `libXdmcp.so.6` | `libxdmcp6` |
| `libstdc++.so.6` | `libstdc++6` |
| `libgcc_s.so.1` | `libgcc-s1` |
| `libc.so.6`, `libm.so.6`, and the ELF loader | `libc6` |

The package manager resolves the transitive XCB libraries from the four direct platform packages. A future binary package should declare the runtime package set appropriate to its target distribution instead of depending on the development packages.

## Display environment

Execution requires an accessible X server with the XKB extension and a valid `DISPLAY`. WSLg satisfies this in the verified WSL environment. A native Linux desktop or another X server may be used as long as those facilities are available.

No OpenGL library is required by this software-rendering build. The OpenGL integration is intentionally deferred.

## Verified build and launch

The following Debug builds completed on 2026-11-07:

```sh
cd gpk/llc
make DEBUG=1 build

cd ../../gpk_games/galaxy_hell_win32
make DEBUG=1 build
```

The resulting `Linux.x64.Debug/galaxy_hell.bin` completed application initialization and remained running until the five-second observation timeout. This confirms startup through the XCB/XKB path; it is not a claim that every physical-key mapping, compose sequence, or fullscreen interaction has been manually exercised.

## Clean rebuild requirement

The current Makefiles do not generate or include compiler dependency files for headers. After changing an ABI-relevant header such as `gpk_window.h`, existing consumer objects can remain stale even though the libraries rebuild. This produced a reproducible stale-layout crash during verification; recompiling `galaxy_hell_win32.o` removed it.

Until header dependency tracking is added, package and release builds must begin from clean intermediate directories or otherwise force every consumer object to rebuild.

## Current verified package versions

These versions record the WSL build environment; they are evidence, not proposed version pins:

| Package | Version |
| --- | --- |
| `build-essential` | `12.12ubuntu2.26.04.2` |
| `g++` | `4:15.2.0-5ubuntu1` |
| `make` | `4.4.1-3` |
| `binutils` | `2.46-3ubuntu2` |
| `libc6-dev` | `2.43-2ubuntu2.4` |
| `libxcb1-dev` | `1.17.0-2ubuntu1` |
| `libxcb-image0-dev` | `0.4.0-2build2` |
| `libxkbcommon-dev` | `1.13.1-1` |
| `libxkbcommon-x11-dev` | `1.13.1-1` |

