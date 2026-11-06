# LLC native window/runtime parity and control proposal

Status: proposal complete; implementation has not started. Pablo reports the existing systems and program forms working; this proposal preserves that working baseline.

Architectural criterion: **build it once, run everywhere**. Each program is authored once against its selected stable lifecycle and data contract. LLC supplies the portable runtime/framework/window substrate, while platform, renderer, module, and CGI adapters provide the applicable host form without infecting application logic with their mechanics.

## Outcome

No new architecture is required. The current architecture is already divided by responsibility. Although these current source files still carry `gpk_` names, `gpk_framework.*` and `gpk_window.*` are LLC-layer facilities and must stay below GPK/`gpk_engine`. They are not an isolated window subsystem: they complement `gpk_runtime.*`, `gpk_app_impl.*`, and `gpk_runtime_module.*`; GPK then specializes the same runtime boundary through `gpk_cgi_runtime.*` and the CGI executable family. Together these facilities define the application model and its different program forms. This is a layer and target assignment, not a filename-renaming proposal.

- `gpk_runtime.*` owns process entry values, command-line/environment parsing, and runtime event queues.
- `gpk_app_impl.*` owns the executable setup/update/draw/cleanup loop.
- `gpk_runtime_module.*` exposes the same application lifecycle when the application is hosted as a module.
- GPK's `gpk_cgi_runtime.*` adapts `SRuntimeValues` to CGI environment, query, content, address, and HTTP-request values without changing LLC.
- LLC's `gpk_framework.*` owns frame timing, GUI orchestration, and the root `SWindow`.
- LLC's `gpk_window.*` owns native window resources, input snapshots, translated system events, and presentation of an application-owned surface.

These pieces compose by program type rather than compete: an ordinary executable uses the runtime and app loop; a windowed interactive application adds the LLC framework/window pair; a hosted application uses the runtime-module adapter; a C++ CGI web script uses `gpk_cgi_runtime.*`, reads its request through environment/standard input, and writes its response through standard output. The lifecycle vocabulary remains coherent while each form owns only the platform resources it actually needs.

“Build it once, run everywhere” therefore means preserving one coherent family of application contracts across Win32 and XCB, software and hardware presentation, direct and module hosting, and command-line or CGI invocation. Each program type keeps its own appropriate contract; selecting a platform or host for that type must not fork its application logic or observable lifecycle.

Galaxy Hell, Smart Dryer, `gpk_engine`, and SSiege prove the behavior expected at those boundaries and at successive architectural levels. The ownership fold is to place the already-working XCB mechanics now located in `gpk_framework.cpp` into the XCB branches in `gpk_window.cpp`, preserving behavior while completing the existing `SWindow` abstraction. No consumer rewrite, new framework, new event model, or desktop/window-manager dependency is justified.

The immediate result is one application contract whose Win32 and XCB backends have matching postconditions. The same boundary preserves SSiege's Win32+D3D11 host and permits a Linux XCB/X11+OpenGL host without changing SSiege game code.

## Authorities and exclusions

### Positive authorities

Galaxy Hell, Smart Dryer, and SSiege are all active, working systems. None is a historical specimen or retired implementation. SSiege is still at the beginning of its development, while its existing boundaries are already authoritative for the responsibilities they demonstrate.

1. **Galaxy Hell** is an authority for the lower systems: software geometry/rasterization, GUI composition, pixel targets, input/events, and presentation. It demonstrates the substrate upon which the newer `gpk_engine` architecture can exist; it is not a competing replacement for that engine layer.

2. **Smart Dryer** is the working XCB authority for that lower-system path. The Raspberry Pi version ran directly over HDMI without a window manager. It ran the complete software rasterizer—the same presentation architecture used by Galaxy Hell—and continuously updated the UI meters with random values. This proves the complete path, not merely window creation or a static framebuffer:

   `application update -> GUI/software rasterization -> owned pixel surface -> XCB presentation`

   The only deliberate platform difference reported for Smart was device policy: the Windows build tolerated absent serial hardware.

3. **`gpk_engine`** is the newer GPK renderer/scene architecture built above the LLC framework/window and the lower systems demonstrated by Galaxy Hell. It governs the eventual D3D11/OpenGL renderer route. Neither the Galaxy Hell substrate nor the current SSiege host arrangement supersedes it.

4. **SSiege** is the early, active consumer-separation authority—not a finished or legacy application. Its game library receives framework input, typed events, and render targets; it does not own `HWND`, XCB, D3D11, or OpenGL policy. Its current Win32 host already proves where platform/renderer selection stays outside game logic, while `gpk_engine` remains the newer renderer architecture.

5. **The current application-model family** defines the destination architecture: `gpk_runtime.*`, `gpk_app_impl.*`, `gpk_runtime_module.*`, `gpk_framework.*`, and `gpk_window.*`, complemented in GPK by `gpk_cgi_runtime.*`. It supports different program types without collapsing their responsibilities into one host. In particular, framework and window remain LLC facilities; `gpk_engine` consumes them from the layer above; CGI semantics do not enter LLC.

6. **The CGI executables and BRT** are valid GPK program forms and regression authorities. They demonstrate several C++ programs composed from the same lower contracts: direct CGI module rendering (`gpk_cgi_rt`), local child-process interception (`gpk_cgi_interceptor`), remote REST/UDP dispatch (`gpk_cgi_rest`), and the windowed UDP-to-child-process bridge (`brt`).

### Explicit exclusions

- The GODS application architecture is retired, but the repository is not disposable: important facilities, including the scene manager, still await deliberate migration into GPK. GODS, GFramework, and GRuntimeWin32 are outside this specific Smart/SSiege/current-framework ownership fold; this proposal neither migrates nor discards their contents.
- No parallel window manager, application controller, GUI abstraction, renderer hierarchy, or consumer-local platform adapter.
- No changes to GUI composition, software rasterization, SSiege game logic, Smart business logic, or serial policy.
- No EWMH/desktop-shell/window-manager requirement on Linux.
- No assumption that a title is window identity.

## Proven current architecture

### Runtime and application lifecycle

`gpk_runtime.h` lines 19-36 define `SRuntimeValues`: platform entry-point data, parsed command-line/environment data, and typed input/output event queues. Lines 53-93 normalize the supported OS entry points into that value.

`gpk_app_impl.h` lines 8-44 host the ordinary setup/update/draw/cleanup loop. Lines 45-123 provide the multithreaded variation. Both use the same application callbacks; neither owns native-window event translation.

`gpk_runtime_module.h` lines 14-21 declare the module lifecycle, lines 26-47 store it, and lines 72-90 adapt the same setup/update/draw/cleanup callbacks to the module ABI. Module hosting therefore changes how the application is invoked, not how a window behaves.

### C++ CGI web-script and bridge forms

`gpk_cgi_runtime.h/.cpp` is the shared GPK specialization. `SCGIRuntimeValues` retains a reference to the unmodified `SRuntimeValues` and adds parsed query elements/key-values, form values, remote address, and request content. `cgiRuntimeValuesLoad()` reads CGI metadata from `EntryPointArgs.Environment`, reads exactly `CONTENT_LENGTH` bytes from `stdin`, and prepares the GPK request representation. `httpRequestInit()` also permits the same request representation to be formed from ordinary command-line positionals. LLC does not acquire CGI knowledge.

The executables prove different program types over that adapter:

- `gpk_cgi_rt/gpk_cgi_rt_main.cpp`: a C++ CGI web script that loads CGI values, selects a CGI module, executes its create/setup/update/render/cleanup/delete lifecycle, and writes the generated HTML response to `stdout`.
- `gpk_cgi_interceptor/gpk_cgi_interceptor_main.cpp`: a C++ CGI web script that converts the request back into an environment/content packet, launches a configured local child process with redirected standard handles, writes request content to its `stdin`, and relays its `stdout` as the CGI response.
- `gpk_cgi_rest/gpk_cgi_rest_main.cpp`: a C++ CGI web script that forwards the environment/content packet to a UDP service and writes the returned JSON response to `stdout`.
- `brt/brt_application_main.h/.cpp`: the complementary windowed service. It uses `gpk_app_impl`, `SFramework`, `SWindow`, and GUI through the ordinary application loop, while a UDP server receives CGI packets and delegates them to child processes through standard I/O. It proves that one application may compose the interactive LLC framework/window form with GPK network/process facilities without altering either lower contract.

These programs remain part of GPK. They are not modified by this proposal; their architectural value and regression value are the separation they demonstrate: standard I/O and CGI transport remain at the specialized consumer/GPK boundary, while LLC remains unchanged.

### Window and framework ownership

`gpk_window.h` lines 23-55 already define one platform-detail type with either Win32 resources or XCB resources. Lines 57-75 define the shared `SWindow` state: native detail, typed event queue, backbuffer, input, dimensions, and lifecycle flags. Lines 77-85 already declare the common update/present/fullscreen surface.

`gpk_framework.h` lines 48-68 own `SRuntimeValues`, GUI, platform detail, and the root `SWindow`. `updateFramework()` is therefore the caller and coordinator of the window contract, not a second implementation of it.

### SSiege separation

- `ssiege.win32.h` lines 19-36: the host owns `SFramework`, optional D3D11/audio state, and `SSiegeApp`.
- `ssiege.win32.cpp` lines 83-93: setup creates the root window through the framework contract.
- `ssiege.win32.cpp` lines 95-137: update consumes typed window/GUI events, calls `ssiegeUpdate()`, then calls `updateFramework()`.
- `ssiege.win32.cpp` lines 139-163: draw selects D3D11 or the software target outside game logic.
- `ssiege.cpp` lines 72-137 and 195-293: the game consumes typed screen/text/keyboard events, `SInput`, and render targets. It has no native-window ownership.

This proves the desired consumer/platform split. The eventual OpenGL route belongs in the newer `gpk_engine` renderer architecture and its host integration, never inside SSiege game logic.

## Required Win32/XCB parity

Both backends must leave the same public state after the same native occurrence.

| Operation | Shared postcondition |
|---|---|
| Create | Valid native resources; `SWindow::Size`, `Input`, and `Resized` initialized; create/resize event available to the consumer. |
| Destroy/close | Native resources released once; `Closed` and typed screen event reflect closure. |
| Frame update | Previous input snapshot retained; current deltas cleared then populated; native events drained into `SInput` and `EventQueue`. |
| Expose/repaint | `Repaint` requests presentation without changing application or GUI ownership. |
| Resize | `PreviousSize`, `Size`, `Resized`, backbuffer expectations, and typed screen resize event agree. |
| Keyboard/text | Current key state and typed keyboard/text events agree. |
| Mouse | Position, deltas, buttons, wheel, and typed mouse events agree. |
| Present software surface | The supplied `g8bgra` surface is presented; the backend does not redraw or reinterpret GUI state. |
| Fullscreen | Shared window state and resize event agree. XCB uses direct X-server geometry when no window manager exists. |
| Hardware renderer | The host binds D3D11 or OpenGL to the native drawable and presents through that renderer; game logic is unchanged. |

Matching behavior does not require identical native calls. It requires identical `SWindow`, `SInput`, and `SEventSystem` effects.

## Exact ownership-fold ledger

Byte ranges are zero-based, half-open ranges computed from the current files on 2026-11-05. They must be regenerated if a source file changes.

| Source | Lines | Bytes | Use |
|---|---:|---:|---|
| `museum/4 - The evolution/reach/smart/smart_2026-11-05_16-57-53-61.log` | 4035-4092 | `[218266,221328)` | Working XCB connection/window/pixmap/GC construction. |
| same | 4097-4160 | `[221451,225107)` | Working software presentation, XCB event pump, input snapshots, timing, and GUI input. |
| same | 4162-4198 | `[225109,226464)` | Working shared XCB framework state. |
| `gpk/llc/gpk_framework.cpp` | 50-165 | `[2069,7667)` | Current copy of the XCB presenter/event pump and shared GUI tail; source to fold, then remove the backend-special frame loop. |
| same | 346-439 | `[20527,25135)` | Current XCB creation plus shared main-window lifecycle; retain behavior while placing native mechanics at the window boundary. |
| `gpk/llc/gpk_window.cpp` | 58-90 | `[2410,3437)` | Destination: existing `windowUpdateTick()`/`windowUpdate()` XCB branches are empty. |
| same | 147-160 | `[7151,8052)` | Destination: existing `windowPresentTarget()` XCB branch is empty. |
| `gpk/llc/gpk_window.h` | 23-85 | `[384,2968)` | Existing public platform/window contract; no replacement type required. |
| `gpk/llc/gpk_runtime.h` | 19-93 | `[359,3658)` | Existing process/runtime boundary; unchanged. |
| `gpk/llc/gpk_app_impl.h` | 8-44 | `[163,2085)` | Existing single-thread lifecycle; unchanged. |
| same | 45-123 | `[2085,6235)` | Existing multithread lifecycle; unchanged. |
| `gpk/llc/gpk_runtime_module.h` | 14-90 | `[272,4865)` | Existing module lifecycle; unchanged. |
| `gpk_games/ssiege.win32/ssiege.win32.h` | 19-36 | `[280,790)` | Proof of host ownership. |
| `gpk_games/ssiege.win32/ssiege.win32.cpp` | 20-163 | `[650,7374)` | Proof of entry point, framework update, and renderer selection. |
| `gpk_games/ssiege/ssiege.cpp` | 13-31, 72-137, 195-293 | `[263,1172)`, `[2853,5479)`, `[7850,12598)` | Proof of GUI/game composition over typed events and render targets. |

The following whole files are unchanged application-form authorities, not extraction ranges in the ownership fold:

| Source | Program form |
|---|---|
| `gpk/llc/gpk_cgi_runtime.h/.cpp` | GPK CGI adaptation of the unchanged LLC runtime boundary. |
| `gpk/gpk_cgi_rt/gpk_cgi_rt_main.cpp` | Direct CGI-module C++ web script. |
| `gpk/gpk_cgi_interceptor/gpk_cgi_interceptor_main.cpp` | Local-process CGI interceptor. |
| `gpk/gpk_cgi_rest/gpk_cgi_rest_main.cpp` | UDP-dispatched CGI REST program. |
| `gpk/brt/brt_application_main.h/.cpp` | Windowed UDP/process bridge. |

## Minimal source transformation

This is a deterministic extraction, not a rewrite.

### 1. Complete `SWindow::windowUpdate()` for XCB

Target: `gpk/llc/gpk_window.cpp`, current lines 58-90.

Adjacent current structure:

```cpp
gpk::err_t gpk::windowUpdateTick(::gpk::SWindow& displayInstance) {
    ...
#if defined(GPK_WINDOWS)
    ...
#elif defined(GPK_XCB)
    (void)displayInstance;
#else
    (void)displayInstance;
#endif
    return quit ? 1 : 0;
}

gpk::err_t gpk::windowUpdate(::gpk::SWindow& displayInstance) {
    displayInstance.EventQueue.clear();
    displayInstance.Resized = false;
    displayInstance.Repaint = false;
    ...
#elif defined(GPK_XCB)

#endif
    return quit ? 1 : 0;
}
```

Proposed change:

- Keep the unchanged queue/flag reset and return contract.
- Move the XCB polling block from `gpk_framework.cpp` lines 101-126 into these XCB branches.
- Preserve the exact native decoding already present.
- Replace its direct framework references with the existing `displayInstance` members.
- Alongside each input mutation, reuse the same `eventEnqueue*` calls already used by the Win32 callback in this file. This is required for SSiege's typed-event path; it is not a new event model.
- Add the missing structure/close cases using the event masks already requested by `xcbWindowCreate()`: configure/resize updates `PreviousSize`, `Size`, and `Resized`; destroy/client-close updates `Closed`; expose sets `Repaint`.
- Free each polled XCB event after processing. The framework block currently does not do so.

No runtime, application, GUI, or renderer code enters this function.

### 2. Complete `windowPresentTarget()` for XCB

Target: `gpk/llc/gpk_window.cpp`, current lines 147-160.

Adjacent current structure:

```cpp
gpk::err_t gpk::windowPresentTarget(SWindow& displayInstance, const g8bgra& targetToPresent) {
    ...
#if defined(GPK_WINDOWS)
    ...
#elif defined(GPK_XCB)
    (void)displayInstance; (void)targetToPresent;
#else
    ...
#endif
    return 0;
}
```

Proposed change:

- Move the exact `xcb_image_create_native()` / `xcb_image_put()` / `xcb_flush()` sequence from `gpk_framework.cpp` lines 81-100 into the empty XCB branch.
- Use `targetToPresent`, not `framework.RootWindow.BackBuffer`; the public function already receives the surface it must present.
- Use `displayInstance.PlatformDetail` for the connection, drawable, and GC.
- Preserve the existing borrowed-memory rule (`image->base = 0` before destroying the XCB image wrapper).
- Clear `displayInstance.Repaint` after successful presentation, matching the working Smart path.

This preserves the full Galaxy Hell/Smart software-rasterizer contract: window code presents pixels; it does not generate them.

### 3. Fold `updateFramework()` back to one platform-neutral frame path

Target: `gpk/llc/gpk_framework.cpp`, current lines 50-165.

Adjacent unchanged lines to retain:

```cpp
timer.Frame();
frameInfo.Frame(::gpk::min(timer.LastTimeMicroseconds, (u3_t)200000));
```

Current platform split to remove:

```cpp
#if defined(GPK_XCB)
    // XCB presentation and event polling, lines 78-126
    gpk::err_t updateResult = 0;
#else
    gpk::err_t updateResult = ::gpk::windowUpdate(mainWindow);
#endif
```

Proposed shared lines:

```cpp
gpk::err_t updateResult = ::gpk::windowUpdate(mainWindow);
```

Keep the existing failure/close checks and GUI processing immediately after it. Replace the Windows-only presentation guard at lines 135-140 with the same existing offscreen validity test for both backends, followed by the existing `windowPresentTarget()` call. Hardware-rendered hosts remain free to keep `BackBuffer` empty or use their renderer-specific present path.

The result is smaller: framework timing and GUI code remain once; backend code resides once in `gpk_window.cpp`.

### 4. Keep creation at the established framework/window seam

Target: `gpk/llc/gpk_framework.cpp`, current lines 346-439.

`mainWindowCreate()` remains the framework-facing creation function because it consumes runtime platform detail. The native XCB mechanics already isolated in `xcbWindowCreate(SWindow&)` remain a window helper; they are not promoted into a new manager.

The XCB branch currently uses `displayDetail` at lines 426-428 without declaring the reference that the Windows branch declares locally. The minimal integration correction is one shared reference before the platform conditional:

```cpp
::gpk::SWindowPlatformDetail & displayDetail = mainWindow.PlatformDetail;
```

The duplicate Windows-local declaration is then removed. No other state is introduced.

`mainWindowDestroy()` receives the symmetric XCB calls for the resources created by `xcbWindowCreate()`, using the handles already stored in `SWindowPlatformDetail`. It must not disconnect a shared connection twice; connection ownership remains exactly where creation establishes it.

### 5. Do not change runtime or module contracts

No changes are proposed to:

- `gpk_runtime.h`
- `gpk_app_impl.h`
- `gpk_runtime_module.h/.cpp`
- `gpk_cgi_runtime.h/.cpp`
- the CGI/BRT program sources
- SSiege game/library files
- GUI or rasterizer files

Those files define and consume the correct lifecycle already. They are included in the proposal to prevent the XCB work from leaking into entry points, application loops, or module callbacks.

## SSiege Linux/OpenGL route

After the parity-preserving ownership fold:

1. Keep `SSiegeApp`, `ssiegeUpdate()`, `ssiegeDraw()`, GUI composition, and typed event handling unchanged.
2. Keep the current Win32+D3D11 host unchanged as the regression authority.
3. Add a Linux host that owns the same `SFramework` and `SSiegeApp` relationship shown by `ssiege.win32.h` lines 19-36, using the newer `gpk_engine` renderer architecture rather than reproducing platform-specific Win32 host internals.
4. Bind the `gpk_engine` OpenGL backend to `SWindowPlatformDetail::IdDrawable` through the selected X11/XCB-compatible context route.
5. Feed the same `SWindow::Input` and `SWindow::EventQueue` into `ssiegeUpdate()`.
6. Select the `gpk_engine` OpenGL draw/present path at the host boundary, exactly where the Win32 host proves renderer selection belongs.

The X server is required; a window manager is not. Fullscreen in that environment is direct window geometry, not desktop policy.

## Native control beyond owned windows

Owned-window consolidation comes first because it completes an existing ownership boundary using existing working code. External-window enumeration/activation/capture/input is a second, system-level capability.

The supplied positive authorities do not contain a settled external-window control API. Therefore this proposal does not invent one or disguise generated names as recovered architecture. The constraints for that later addition are already clear:

- enumerate through the one OS window system;
- map backend handles to opaque GPK identifiers;
- keep `HWND`/`xcb_window_t` private to the backend;
- use titles only as metadata;
- target one explicit identifier unless a broadcast is explicit;
- never own or destroy a foreign window;
- keep optional desktop policy separate from X-server mechanics.

That surface should be proposed only after the owned `SWindow` ownership fold is built and exercised, and only from the smallest missing operations then demonstrated.

## Validation matrix

Pablo reports the current systems working. The following checks are regression validation for the ownership fold; they are not prerequisites for accepting the existing baseline as working. No future implementation result may be called complete from compilation alone.

1. Build the owning solution in the requested configuration without changing runtime/module consumers.
2. Re-run an existing Win32 software-rasterized consumer and confirm input, resize, expose, close, fullscreen, and pixel presentation.
3. Re-run SSiege Win32+D3D11 unchanged.
4. Run the Smart-style XCB software path without a window manager and confirm:
   - the full software-rasterized UI is visible;
   - random meter values continue updating;
   - keyboard and mouse update both `SInput` and typed event queues;
   - resize/repaint/close have the same public effects as Win32.
5. Run Galaxy Hell through the same software-present contract to confirm that the rasterizer output is not altered by the window extraction.
6. Add and run the SSiege XCB/OpenGL host through `gpk_engine` only after steps 1-5 pass; confirm the game/library source remains unchanged.
7. Exercise direct executable hosting (`gpk_app_impl`) and module hosting (`gpk_runtime_module`) to prove that the same window behavior is independent of entry-point form.
8. Exercise a CGI web-script program separately through standard input/output to prove that the LLC window-ownership fold did not contaminate the non-windowed program form or add CGI semantics to LLC.

## Implementation order

1. Move the existing XCB presenter into `windowPresentTarget()`.
2. Move the existing XCB event pump into `windowUpdate()`/`windowUpdateTick()` and connect the existing typed event enqueuers.
3. Reduce `updateFramework()` to the shared update/present/GUI sequence.
4. Correct the one missing `displayDetail` binding and complete symmetric XCB destruction.
5. Build and execute the parity matrix.
6. Only then add the SSiege OpenGL host through the newer `gpk_engine` architecture.
7. Only after the owned-window fold preserves the working parity, propose the minimal external-window control surface from demonstrated missing operations.

The intended source diff is mostly red in `gpk_framework.cpp` and narrowly green in the already-empty XCB branches of `gpk_window.cpp`: existing working mechanics move to their established owner; application, GUI, rasterizer, runtime, module, and game contracts remain intact.
