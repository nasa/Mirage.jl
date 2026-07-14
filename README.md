# Mirage.jl

[![built with Julia](https://img.shields.io/badge/built%20with-Julia-9558B2.svg?logo=julia&logoColor=white)](https://julialang.org)
[![CI](https://github.com/groverburger/Mirage.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/groverburger/Mirage.jl/actions/workflows/CI.yml)

Mirage.jl is a hardware-accelerated 2D and 3D graphics library for Julia with an
HTML5 Canvas–style API, plus a batteries-included layer for building **standalone
desktop GUI applications** on top of [Dear ImGui](https://github.com/ocornut/imgui)
(via [CImGui.jl](https://github.com/Gnimuc/CImGui.jl)) and GLFW.

You write draw calls like `Mirage.fillrect` and `Mirage.drawimage` instead of
managing shaders and vertex buffers, drop your rendered canvases straight into
ImGui windows, and iterate on the whole application live from the Julia REPL —
start the app, use it, edit a function, and see the change without losing your state.

Mirage.jl is used in production in **SHERPA**, a lunar surface mission-planning tool
at the NASA Ames Research Center.

## Features

- **HTML5 Canvas–style 2D API:** `Mirage.fillrect`, `Mirage.fillcircle`,
  `Mirage.drawimage`, paths, `Mirage.text`, and a save/restore transform stack.
- **3D rendering:** meshes, perspective/lookat cameras, OBJ loading, custom
  shaders — the same minimal, immediate-mode philosophy.
- **Desktop GUI application layer:** `MirageApp` wires OpenGL + Dear ImGui + GLFW
  together, with docking, canvases-in-windows, input callbacks, a bundled
  DPI-scaled UI font (Roboto), and programmatic dock layouts.
- **REPL live-reload workflow:** `run_live!` hot-reloads your code while the app
  runs (via a `Revise` package extension), and errors in your frame code are
  logged and skipped — not fatal — so you can fix them live.
- **OpenGL backend:** high-performance rendering powered by ModernGL.jl.

## Why Mirage?

Julia has excellent tools for computation, but building an interactive *desktop
application* around that computation — maps, custom real-time visualizations,
mission dashboards — has usually meant either a web stack or gluing low-level
libraries together yourself. Mirage exists for exactly that gap. How it compares to
what you might reach for instead:

| If you want… | Consider | How Mirage differs |
|---|---|---|
| Publication-quality plots, scientific viz | [Makie/GLMakie](https://makie.org) | Makie is a (fantastic) plotting system with reactive `Observable`s; it isn't an app framework — no windowing/docking/widget-panel story, embedding it in a GUI is experimental, and it's a heavyweight dependency. Mirage is the opposite trade: a full app shell + free-form canvas, no plotting (pair it with [ImPlot.jl](https://github.com/wsphillips/ImPlot.jl) for charts — SHERPA does). |
| Immediate-mode UI, DIY everything | [CImGui.jl](https://github.com/Gnimuc/CImGui.jl) directly | Mirage is *built on* CImGui.jl and stays fully interoperable with it. What it adds: the Canvas2D-style drawing API (no shaders/buffers), the app lifecycle (`MirageApp`, docking, DPI, bundled font), canvas-in-window render targets, error-resilient frames, and the Revise live-reload loop. |
| Native retained-mode widgets, form-style apps | [Gtk4.jl](https://github.com/JuliaGtk/Gtk4.jl), [QML.jl](https://github.com/JuliaGraphics/QML.jl) | Mature bindings to native toolkits — a good fit for conventional widget-centric apps. Retained-mode: you build widget trees and wire signals/QML files, and custom real-time 2D/3D drawing is where you leave the paved road. Mirage inverts that: the GPU canvas is the center of the app and widgets float around it, redrawn every frame from plain Julia state. |
| A web/Electron UI | [Genie/Stipple.jl](https://github.com/GenieFramework/Genie.jl), [Dash.jl](https://github.com/plotly/Dash.jl), Blink.jl | Great for browser delivery. For a desktop tool it means a server layer, serialization at every boundary, and often two languages. SHERPA started as React + Julia over HTTP and was rebuilt on Mirage precisely to collapse that into one language, one process. |
| Canvas-style *static* vector graphics | [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl) | Luxor has a similar drawing feel but renders to files (SVG/PNG/PDF). Mirage is that feel at interactive framerates on the GPU, with input handling and a UI toolkit attached. |

Reasons *not* to pick Mirage: you mainly need plots (Makie), a conventional
widget-heavy form app (Gtk4/QML), browser deployment (Genie), or static artwork
(Luxor). Mirage's sweet spot is the interactive graphical tool: custom rendering at
its heart, controls around it, developed live from the REPL.

## Installation

Mirage's registration in the Julia General registry is in progress. Until it
completes, install straight from GitHub:

```julia
import Pkg
Pkg.add(url = "https://github.com/groverburger/Mirage.jl")
```

(Once registered: `pkg> add Mirage`.) Requires Julia 1.11+ — Mirage tracks current
Julia rather than LTS. To run the bundled examples, clone the repo:

```sh
git clone https://github.com/groverburger/Mirage.jl
cd Mirage.jl
julia --project=examples examples/01_minimal_app.jl
```

## Quick start

A spinning square on a full-window canvas:

```julia
using Mirage

app = MirageApp("Spinning Square"; width = 800, height = 600)

run!(app) do a
    draw_background_canvas!(a) do canvas, viewport
        Mirage.save()
        Mirage.translate(canvas.width / 2, canvas.height / 2)
        Mirage.rotate(time())
        Mirage.fillcolor(Mirage.rgba(255, 40, 40))
        Mirage.fillrect(-55, -55, 110, 110)
        Mirage.restore()
    end
end
```

`draw_background_canvas!` gives you a canvas that fills the window; the callback
receives it with a pixel-space 2D projection already applied, so you can draw
immediately. Close the window (or call `stop!(app)`) and `run!` tears everything
down.

## How the API is organized

**The application layer is exported.** `using Mirage` brings in the front door:
`MirageApp`, `run!`, `run_live!`, `stop!`, `draw_canvas!`, `draw_background_canvas!`,
`dock_layout!`, `CanvasViewport`, input callbacks, and friends. These names are
unique to Mirage.

**The drawing API is used qualified**, mirroring how the HTML5 canvas is always
accessed through its context (`ctx.fillRect(...)` → `Mirage.fillrect(...)`):

- Shapes & styles: `Mirage.fillrect`, `Mirage.fillcircle`, `Mirage.rect`,
  `Mirage.circle`, `Mirage.fillcolor`, `Mirage.strokecolor`, `Mirage.strokewidth`,
  `Mirage.rgba`
- Paths: `Mirage.beginpath`, `Mirage.moveto`, `Mirage.lineto`, `Mirage.closepath`,
  `Mirage.fill`, `Mirage.stroke`
- Transforms: `Mirage.save`, `Mirage.restore`, `Mirage.translate`, `Mirage.rotate`,
  `Mirage.scale`
- Text & images: `Mirage.text`, `Mirage.drawimage`, `Mirage.load_texture`
- 3D: `Mirage.create_mesh`, `Mirage.draw_mesh`, `Mirage.load_obj_mesh`,
  `Mirage.create_cube`, `Mirage.create_uv_sphere`,
  `Mirage.update_perspective_projection_matrix`, `Mirage.lookat`
- Custom shaders: `Mirage.create_shader_program`, `Mirage.initialize_shader_uniform!`,
  `Mirage.set_uniform`, `Mirage.VertexAttribute`

**Embedding (advanced):** to host Mirage inside your own GLFW/OpenGL window and
render loop, call `Mirage.initialize_render_context()` once after creating your GL
context, then use the drawing API and `Mirage.create_canvas`/`Mirage.set_canvas`
directly; pair with `Mirage.cleanup_render_context()` at shutdown. (`MirageApp`
does all of this for you.)

## Building a desktop GUI application

Build your UI with Dear ImGui and render custom 2D/3D content into docked windows
with `draw_canvas!`:

```julia
using Mirage
using CImGui        # the immediate-mode UI toolkit (add it to your project)

function main()
    app = MirageApp("My Julia App"; width = 1200, height = 800)
    speed = Ref(1.0f0)
    laid_out = Ref(false)

    run!(app) do a
        # Dock the canvas to fill the center, controls on the left (runs once;
        # everything stays user-dockable afterward).
        if !laid_out[]
            dock_layout!(a; center = "Viewport", left = "Controls", left_size = 0.25)
            laid_out[] = true
        end

        CImGui.Begin("Controls")
        CImGui.SliderFloat("spin speed", speed, 0.0f0, 5.0f0)
        CImGui.End()

        CImGui.Begin("Viewport")
        draw_canvas!(a, :scene) do canvas, viewport
            Mirage.translate(canvas.width / 2, canvas.height / 2)
            Mirage.rotate(time() * speed[])
            Mirage.fillcolor(Mirage.rgba(255, 60, 60))
            Mirage.fillrect(-50, -50, 100, 100)
        end
        CImGui.End()
    end
end

main()
```

Two layout patterns are supported out of the box:

| Pattern | How | Good for |
|---|---|---|
| **Docked panes** | `dock_layout!` + `draw_canvas!` in a docked window | side-by-side canvas + settings panels |
| **Background canvas** | `draw_background_canvas!` + floating panels | maps/viewers where the canvas *is* the app |

See the [`examples/`](examples/) folder for runnable versions of both, plus mouse
interaction and a 3D orbit-camera viewer.

### Continuous vs. event-driven rendering

`run!` renders continuously by default (`animate = true`), like a game loop. For
tools that sit idle most of the time, pass `animate = false`: the loop blocks on
input events and repaints only when something happens — `request_frame!(app)` and
`stop!(app)` wake it from timers or other tasks. Pass a function `app -> Bool` to
decide per frame (e.g. animate only while a simulation is playing).

### The REPL live-reload workflow

With Revise tracking your code, `run_live!` re-reads your edits each frame. The
workflow that makes GUI development feel like ordinary Julia:

1. `using Revise`, then load your code so Revise tracks it: `includet("app.jl")`
   (or `Revise.track(MyModule, "app.jl")`, or make it a package — packages are
   tracked automatically).
2. Start the app and use it — load data, pan the camera, set up a scenario.
3. Edit a function, save — the running app picks it up next frame, state intact.
4. Broke something? The error is logged, frames are skipped, and the app recovers
   the moment you save a fix. No restart.

`Revise` is an **optional** dependency: without it loaded, `run_live!` logs a
warning and runs without hot-reloading (the integration lives in the
`MirageReviseExt` package extension). Note that a plain `include` is not tracked —
use `includet` or `Revise.track`.

## Limitations & platform notes

Honest edges to know about before you commit:

- **Main thread only.** GLFW requires the window and render loop to run on Julia's
  main thread. `request_frame!` and `stop!` are safe to call from other tasks and
  timers (they wake the loop); other Mirage calls are not thread-safe.
- **One app at a time.** Mirage keeps a single global render context, so run one
  `MirageApp` per process (sequential apps are fine). Multi-window support is a
  known design ceiling, not a roadmap promise.
- **Platforms:** developed and used in production on macOS (Apple Silicon); CI runs
  on Linux. Windows should work through the same GLFW/CImGui binary stack but is
  not yet tested — reports welcome.
- **Julia 1.11+** (not LTS): the package tracks current Julia.
- **First-window latency:** like most Julia GL stacks, expect several seconds of
  JIT on the first window per session; subsequent opens are fast.

## Testing

```julia
pkg> test
```

The test suite runs headless by default (it exercises the CPU-side API and the
package's load/extension behavior). To also open the interactive demo windows:

```julia
MIRAGE_TEST_INTERACTIVE=1 julia --project -e 'using Pkg; Pkg.test()'
```

## Contributing

Contributions are welcome! Please open an issue or pull request on the
[GitHub repository](https://github.com/groverburger/Mirage.jl).

## License

Mirage.jl is licensed under the Apache License 2.0. See [LICENSE](LICENSE) and
[NOTICE](NOTICE) for details. The bundled Roboto UI font is © Google Inc.,
Apache-2.0 (see `assets/fonts/LICENSE`).
