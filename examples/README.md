# Mirage.jl examples

Five standalone Mirage applications. Run any file directly or call its module's
`main()`.

## Quick start

```sh
julia --project=examples -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
julia --project=examples examples/01_minimal_app.jl
```

## Examples

| File | Selector | Covers |
|------|----------|--------|
| [`01_minimal_app.jl`](01_minimal_app.jl) | `minimal_app` | Minimal animated app |
| [`02_live_reload.jl`](02_live_reload.jl) | `live_reload` | Revise and `run_live!` |
| [`03_orbital_dynamics.jl`](03_orbital_dynamics.jl) | `orbital_dynamics` | Interactive four-body Verlet simulation |
| [`04_scene_viewer_3d.jl`](04_scene_viewer_3d.jl) | `scene_viewer_3d` | Meshes, textures, shaders, camera, paths, text |
| [`05_rendering_gallery_2d.jl`](05_rendering_gallery_2d.jl) | `rendering_gallery_2d` | Shapes, paths, text, images, offscreen canvas |

## Interactive runner

Normal `Pkg.test()` runs without windows. Opt in to launch every example:

```sh
MIRAGE_TEST_INTERACTIVE=1 julia --project -e 'using Pkg; Pkg.test()'
```

Select examples with a comma-separated list:

```sh
MIRAGE_TEST_INTERACTIVE=1 MIRAGE_TEST_EXAMPLES=scene_viewer_3d,rendering_gallery_2d \
  julia --project -e 'using Pkg; Pkg.test()'
```

## Live reload

From a REPL:

```julia
using Revise
includet("examples/02_live_reload.jl")
LiveReload.main()
```

Edit `scene!`, save, and the existing window updates in place.
