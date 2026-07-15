# Mirage.jl

[![built with Julia](https://img.shields.io/badge/built%20with-Julia-9558B2.svg?logo=julia&logoColor=white)](https://julialang.org)
[![CI](https://github.com/groverburger/Mirage.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/groverburger/Mirage.jl/actions/workflows/CI.yml)

Mirage.jl is a hardware-accelerated 2D and 3D graphics library for Julia with an
HTML5 Canvas–style API, plus a batteries-included layer for building **standalone
desktop GUI applications** on top of [Dear ImGui](https://github.com/ocornut/imgui)
(via [CImGui.jl](https://github.com/Gnimuc/CImGui.jl)) and GLFW.

You write draw calls like `Mirage.fillrect` and `Mirage.drawimage` instead of
managing shaders and vertex buffers, drop your rendered canvases straight into
ImGui windows, and iterate on the whole application live from the Julia REPL.
Start the app, use it, edit a function, and see the change without losing your state!

Mirage.jl is used in production in **SHERPA**, a lunar rover strategic
mission-planning tool at the NASA Ames Research Center, used in projects such
as VIPER.

## Features

- **HTML5 Canvas–style 2D API:** `Mirage.fillrect`, `Mirage.fillcircle`,
  `Mirage.drawimage`, paths, `Mirage.text`, and a save/restore transform stack.
- **3D rendering:** meshes, perspective/lookat cameras, OBJ loading, custom
  shaders. The same minimal, immediate-mode philosophy.
- **Desktop GUI application layer:** `MirageApp` wires OpenGL + Dear ImGui + GLFW
  together, with docking, canvases-in-windows, input callbacks, a bundled
  DPI-scaled UI font (Roboto), and programmatic dock layouts.
- **REPL live-reload workflow:** `run_live!` hot-reloads your code while the app
  runs (via a `Revise` package extension), and errors in your frame code are
  logged and skipped so you can fix them live.
- **OpenGL backend:** high-performance rendering powered by ModernGL.jl.

## Why Mirage?

Mirage is for interactive desktop tools centered on custom GPU rendering.

| Need | Use |
|---|---|
| Custom 2D/3D desktop tool | Mirage |
| Scientific plots | [Makie](https://makie.org) |
| Low-level immediate-mode UI | [CImGui.jl](https://github.com/Gnimuc/CImGui.jl) |
| Conventional forms | [Gtk4.jl](https://github.com/JuliaGtk/Gtk4.jl) or [QML.jl](https://github.com/JuliaGraphics/QML.jl) |
| Browser deployment | [Genie.jl](https://github.com/GenieFramework/Genie.jl) or [Dash.jl](https://github.com/plotly/Dash.jl) |
| Static vector graphics | [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl) |

## Installation

Until Mirage is registered, install it from GitHub:

```julia
import Pkg
Pkg.add(url = "https://github.com/groverburger/Mirage.jl")
```

Requires Julia 1.11+. To run the examples:

```sh
git clone https://github.com/groverburger/Mirage.jl
cd Mirage.jl
julia --project=examples examples/01_minimal_app.jl
```

## Quick start

Start with [`examples/01_minimal_app.jl`](examples/01_minimal_app.jl). The
[`examples/`](examples/) folder also covers live reload, mouse input, and 3D.

## How the API is organized

`using Mirage` exports the application layer:
`MirageApp`, `run!`, `run_live!`, `stop!`, `draw_canvas!`, `draw_background_canvas!`,
`dock_layout!`, `CanvasViewport`, and input callbacks.

Use the drawing API with the `Mirage.` prefix:

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

For custom GLFW/OpenGL hosts, use `Mirage.initialize_render_context()` and
`Mirage.cleanup_render_context()` instead of `MirageApp`.

## Building a desktop GUI application

Build the UI with CImGui and render into either layout:

| Pattern | How | Good for |
|---|---|---|
| Docked panes | `dock_layout!` + `draw_canvas!` | Canvas with panels |
| Background canvas | `draw_background_canvas!` | Canvas with overlays |

### Continuous vs. event-driven rendering

`run!` renders continuously by default. Pass `animate = false` for event-driven
rendering and call `request_frame!(app)` when background work needs a repaint.

### The REPL live-reload workflow

Load code with Revise's `includet`, then use `run_live!`. Saved changes appear in
the running app; frame errors are logged so the app can recover after the next edit.

## Limitations & platform notes

- Run the window and render loop on Julia's main thread.
- Run one `MirageApp` at a time per process.
- macOS is production-tested; Linux runs in CI; Windows is untested.
- Julia 1.11+ is required.
- The first window in a session incurs JIT latency.

## Testing

```julia
pkg> test
```

Interactive tests:

```julia
MIRAGE_TEST_INTERACTIVE=1 julia --project -e 'using Pkg; Pkg.test()'
```

## Contributing

Open an issue or pull request on [GitHub](https://github.com/groverburger/Mirage.jl).

## License

Apache 2.0. See [LICENSE](LICENSE), [NOTICE](NOTICE), and
[`assets/fonts/LICENSE`](assets/fonts/LICENSE).
