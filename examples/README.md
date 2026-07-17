# Mirage.jl examples

Five self-contained desktop applications form the canonical graphical example suite.
Each file defines a uniquely named module with a callable `main()` and also runs
directly as a script.

From the repository root:

```sh
julia --project=examples -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
julia --project=examples examples/01_minimal_app.jl
```

| File | What it shows |
|------|---------------|
| [`01_minimal_app.jl`](01_minimal_app.jl) | The smallest animated Mirage/CImGui app. |
| [`02_live_reload.jl`](02_live_reload.jl) | Revise tracking and `run_live!` without losing app state. |
| [`03_orbital_dynamics.jl`](03_orbital_dynamics.jl) | Four-body position-Verlet simulation, camera navigation, dragging/throwing, inspection, and numerical diagnostics. |
| [`04_scene_viewer_3d.jl`](04_scene_viewer_3d.jl) | Meshes, OBJ loading, textures, Phong shading, orbit camera, 3D paths, and scene text. |
| [`05_rendering_gallery_2d.jl`](05_rendering_gallery_2d.jl) | Primitives, paths, transforms, text, loaded images, and an offscreen canvas. |

The orbital app conditionally animates only while its simulation is running. A
normal package test loads every module headlessly; interactive example runs are
explicitly opt-in:

```sh
MIRAGE_TEST_INTERACTIVE=1 julia --project -e 'using Pkg; Pkg.test()'
MIRAGE_TEST_INTERACTIVE=1 MIRAGE_TEST_EXAMPLES=scene_viewer_3d,rendering_gallery_2d \
  julia --project -e 'using Pkg; Pkg.test()'
```

Valid selection names are `minimal_app`, `live_reload`, `orbital_dynamics`,
`scene_viewer_3d`, and `rendering_gallery_2d`.

## Live reload

Run `02_live_reload.jl` directly, or load it as a tracked loose script from a REPL:

```julia
using Revise
includet("examples/02_live_reload.jl")
LiveReload.main()
```

Edit `scene!`, save, and the existing window updates in place.
