# Mirage.jl

[![built with Julia](https://img.shields.io/badge/built%20with-Julia-9558B2.svg?logo=julia&logoColor=white)](https://julialang.org)
[![CI](https://github.com/nasa/Mirage.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/nasa/Mirage.jl/actions/workflows/CI.yml)
[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://nasa.github.io/Mirage.jl/dev/)

Mirage.jl is a multiplatform, integrated, OpenGL-powered framework for building **interactive
desktop applications** in Julia, especially GUIs for simulations and scientific
software. Its HTML5 Canvas–style 2D and 3D drawing API, [Dear
ImGui](https://github.com/ocornut/imgui) interface (via
[CImGui.jl](https://github.com/Gnimuc/CImGui.jl)), and GLFW application runtime
work together as one system.

Draw with calls like `Mirage.fillrect` and `Mirage.drawimage`, arrange canvases
inside dockable GUI windows. You don't have to worry about managing shaders,
vertex buffers, or window plumbing unless you want to.

**Works natively with Revise.** Run the application from the Julia REPL,
edit it live, and watch it keep its state while the interface updates in real time.

Mirage.jl is used in production in **SHERPA**, a lunar rover strategic
mission-planning tool at the NASA Ames Research Center, used in projects such
as VIPER:
<p align="center">
  <img width="900" alt="SHERPA lunar rover mission-planning GUI built with Mirage.jl" src="https://github.com/user-attachments/assets/61666423-a3c9-4c6e-8be8-9927da380225" />
</p>

## Features

- **2D canvas API** — shapes, images, paths, text, and transforms.
- **3D rendering** — meshes, cameras, OBJ models, and custom shaders.
- **GPU acceleration** — powered by ModernGL.jl.
- **Desktop apps** — OpenGL, Dear ImGui, and GLFW through `MirageApp`.
- **Docking** — canvas windows and programmatic layouts.
- **Input** — mouse, keyboard, and window callbacks.
- **High-DPI UI** — automatic scaling and bundled Roboto.
- **Live reload** — edit running apps with `run_live!` and Revise.
- **Recoverable errors** — fix frame code without restarting the app.

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
