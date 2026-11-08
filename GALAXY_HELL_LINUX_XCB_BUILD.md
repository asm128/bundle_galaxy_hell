# Galaxy Hell Linux/XCB build

## Target

Build and run Galaxy Hell on Linux through the existing XCB framework path. Keep the game and software renderer unchanged. Keep every generated file in the checkout's configured `Linux.x64.Debug` and `obj/Linux.x64.Debug` directories.

SSiege/OpenGL is a separate follow-up. It is not part of this pass.

## Existing path being used

- `gpk/llc/gpk_window.*` already owns the XCB connection, window, input events, resize events, close protocol and software back-buffer presentation.
- `gpk/llc/gpk_framework.*` already runs the shared update/draw/present loop.
- `gpk/llc/gpk_runtime.*` and `gpk/llc/gpk_app_impl.h` already provide the non-Windows entry path.
- `gpk_games/galaxy_hell` already contains the platform-neutral game and software renderer.
- `gpk_games/galaxy_hell_win32` contains the current standalone host. Its game calls are portable; only the WGL/XAudio shell requires a Windows guard.

No replacement window, event, rendering or application model is being introduced.

## Console

The inherited console rejects WSL with `WSL_E_CONSOLE` because its legacy console mode is active. Linux commands are therefore launched in a separate hidden console process. `HKCU\\Console\\ForceV2` is set to `1` only while that process starts and is restored immediately afterward.

## Linux prerequisites

Installed in the existing Ubuntu WSL distribution:

```text
build-essential
pkg-config
libxcb1-dev
libxcb-image0-dev
```

The installation and build logs are kept under `Linux.x64.Debug`.

## LLC build corrections

The existing `gpk/llc/Makefile` selected C++17 while the current headers use constraints and static locals in constexpr functions. The latter is a C++23 facility, so the build definition now selects C++23 instead of rewriting the registry implementation.

`gpk_typeint.h` defined `refcount_t` with the undeclared library name `intptr_t` even though the framework had already defined its own pointer-sized signed type, `sP_t`. `refcount_t` now uses `sP_t`.

The Makefile wildcard also selected `gpk_arduino_string.cpp` for the XCB build. The first attempted response was to exclude it. That was wrong: platform-specific translation units remain in the common source list and guard their implementation like the rest of the framework. The wildcard was restored. The file's stale `LLC_ARDUINO`, `llc::` and `llc_arduino_string.h` migration was completed with the corresponding GPK names. Its directly included `gpk_arduino_stream.h` had the same stale prefix in its include guard, platform guard, namespace and type header; that named header received the same mechanical correction. Both translation units now become empty outside Arduino without special Makefile handling.

The next pass exposed another mechanically incomplete renamed pair, `gpk_ccsds.h/.cpp`. Only that pair was changed from its stale `llc` names to its existing `gpk` filename/namespace. It also exposed two color equality operators whose `constexpr` bodies reinterpreted object storage. Their existing constexpr `u2_t` conversion is now used directly, preserving both the contract and compile-time evaluation.

The event owner already converts `array_pod<T>` directly to `view<const T>`, so the vanished `Data.cu8()` accessor in `SEvent` was reduced to `Data`. The Linux module branch already owns the `dlopen`/`dlclose`/`dlsym` macros; it now includes their owning `<dlfcn.h>` header in that same branch.

`gpk_circuit.h/.cpp` was the next mechanically incomplete renamed pair selected by the common build. Its stale `llc` includes, guards and namespaces were changed to the pair's existing `gpk` identity without changing either circuit formula.

C++23 warns when the value of an assignment to the volatile reference count is used by the same expression. `ref_allocate()` now performs the existing assignment first and tests the resulting count on the next line. Allocation, failure cleanup and ownership transfer remain unchanged.

The safe-handle helpers now include the C headers that declare their existing `free` and `fclose` calls. The socket RAII closer keeps the Windows `closesocket` call and uses POSIX `close` in its existing non-Windows branch. Three JSON labels used only by optional info logging are explicitly consumed when that logging compiles away, preserving warning-clean builds without suppressing warnings.

`gpk_pack.h/.cpp` was another incomplete file/namespace rename and received only the corresponding prefix correction. A diagnostic `OutputDebugStringA` call in `gpk_index.cpp` is now confined to Windows. `gpk::string` intentionally converts to both mutable and const views; an exact `str(const string&)` overload beside the type now selects its const string view without ambiguity.

## Current checkpoint

The separate Linux console works. Package installation works. The first LLC build reached actual C++ compilation and exposed the three build-definition issues above. The next checkpoint is a complete `Linux.x64.Debug/llc.a`, followed by the engine, Galaxy Hell core and the thin XCB host.

## Final verification still required

1. Build LLC, engine, Galaxy Hell core and host with no files outside `OutDir`/`IntDir`.
2. Launch the Linux executable through WSLg/XCB.
3. Confirm a visible Galaxy Hell frame.
4. Confirm keyboard and pointer input reach the existing game update path.
5. Record the exact successful commands and output files here.
