# Mirage.jl

[![built with Julia](https://img.shields.io/badge/built%20with-Julia-9558B2.svg?logo=julia&logoColor=white)](https://julialang.org)
[![CI](https://github.com/nasa/Mirage.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/nasa/Mirage.jl/actions/workflows/CI.yml)

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

## Installation

Until Mirage is registered, install it from GitHub:

```julia
import Pkg
Pkg.add(url = "https://github.com/nasa/Mirage.jl")
```

Requires Julia 1.11+. To run the examples:

```sh
git clone https://github.com/nasa/Mirage.jl
cd Mirage.jl
julia --project=examples -e 'using Pkg; Pkg.instantiate()'
julia --project=examples examples/01_minimal_app.jl
```

## Usage

The five canonical [`examples/`](examples/) cover the app lifecycle, live reload,
an interactive orbital simulation, comprehensive 3D rendering, and a compact 2D
gallery. See the [`docs/`](docs/) for the complete API.

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

```sh
MIRAGE_TEST_INTERACTIVE=1 julia --project -e 'using Pkg; Pkg.test()'
```

Run only selected examples by their names:

```sh
MIRAGE_TEST_INTERACTIVE=1 MIRAGE_TEST_EXAMPLES=orbital_dynamics,rendering_gallery_2d \
  julia --project -e 'using Pkg; Pkg.test()'
```

Interactive windows are never opened by a normal `Pkg.test()` run.

## Contributing

Open an issue or pull request on [GitHub](https://github.com/nasa/Mirage.jl).

## License

Apache 2.0. See [LICENSE](LICENSE), [NOTICE](NOTICE), and
[`assets/fonts/LICENSE`](assets/fonts/LICENSE).
