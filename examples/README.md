# Mirage.jl examples

Minimal, self-contained desktop apps that exercise the `MirageApp` API. They double
as a place to *feel* the API before building a real app.

## Running

Each example is a standalone script. From the repository root:

```sh
julia --project=examples examples/01_minimal_app.jl
```

The first run instantiates the example environment (it uses the in-repo Mirage via a
path dependency). Close the app window to exit.

## The live-reload workflow

`02_live_reload.jl` demonstrates the hot-reload loop. It works in script mode
directly (the file registers itself with Revise):

```sh
julia --project=examples examples/02_live_reload.jl
# now edit the `scene!` function in the file, save, and watch the running window update
```

or from the REPL:

```julia
using Revise
includet("examples/02_live_reload.jl")   # `includet` = Revise-tracked include
LiveReload.main()
```

Live reload requires Revise to be *tracking* the file — a plain `include` won't
reload, and `run_live!` warns if Revise isn't loaded at all.

## The examples

| File | What it shows |
|------|---------------|
| `01_minimal_app.jl`   | Smallest useful app: an ImGui control panel driving a 2D canvas. |
| `02_live_reload.jl`   | `run_live!` + Revise hot-reload of your draw code. |
| `03_paint_2d.jl`      | Mouse input via `CanvasViewport`; accumulating drawing state. |
| `04_mesh_viewer_3d.jl`| 3D mesh rendering in a canvas with drag-to-orbit and scroll-to-zoom. |
