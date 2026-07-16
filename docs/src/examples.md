# Examples

Run examples from the repository root:

```sh
julia --project=examples -e 'using Pkg; Pkg.instantiate()'
julia --project=examples examples/01_minimal_app.jl
```

| File | Focus |
|------|-------|
| [`01_minimal_app.jl`](https://github.com/nasa/Mirage.jl/blob/master/examples/01_minimal_app.jl) | Small animated app |
| [`02_live_reload.jl`](https://github.com/nasa/Mirage.jl/blob/master/examples/02_live_reload.jl) | Revise workflow |
| [`03_orbital_dynamics.jl`](https://github.com/nasa/Mirage.jl/blob/master/examples/03_orbital_dynamics.jl) | Interactive four-body simulation |
| [`04_scene_viewer_3d.jl`](https://github.com/nasa/Mirage.jl/blob/master/examples/04_scene_viewer_3d.jl) | Meshes, textures, lighting, and camera controls |
| [`05_rendering_gallery_2d.jl`](https://github.com/nasa/Mirage.jl/blob/master/examples/05_rendering_gallery_2d.jl) | 2D drawing and offscreen canvases |

Each file defines a module with `main()` and also runs as a script.

Interactive smoke tests are opt-in:

```sh
MIRAGE_TEST_INTERACTIVE=1 julia --project -e 'using Pkg; Pkg.test()'
```

Select examples with `MIRAGE_TEST_EXAMPLES=orbital_dynamics,scene_viewer_3d`.
