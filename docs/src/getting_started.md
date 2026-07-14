# Getting Started

This guide walks you through installing Mirage.jl and opening your first application
window.

## Installation

First, you need Julia 1.11 or newer, available from the
[official Julia website](https://julialang.org/downloads/).

Until Mirage.jl's registration in the General registry completes, install it
directly from GitHub:

```julia
import Pkg
Pkg.add(url = "https://github.com/groverburger/Mirage.jl")
```

Once registered, this becomes simply `Pkg.add("Mirage")`.

## Your first app: a spinning square

A Mirage application is a [`MirageApp`](@ref) (window + OpenGL + Dear ImGui context)
driven by [`run!`](@ref), which calls your frame function every frame. Drawing
happens inside a *canvas*; the easiest one is [`draw_background_canvas!`](@ref),
which fills the whole window:

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

Run it and a window appears with a red square spinning in its center. Close the
window (or call [`stop!`](@ref)) and `run!` tears everything down.

Three things to notice:

1. **The app layer is exported** (`MirageApp`, `run!`, `draw_background_canvas!`),
   while **drawing functions are called qualified** — `Mirage.fillrect(...)`,
   `Mirage.save()` — mirroring how the HTML5 canvas is always accessed through its
   context (`ctx.fillRect(...)`).
2. The canvas callback receives the canvas with a **pixel-space 2D projection
   already applied**, so you can draw immediately in pixel coordinates.
3. `run!` renders **continuously by default** (`animate = true`). Pass
   `animate = false` for event-driven rendering that only repaints on input — see
   [Core Concepts](concepts.md).

## Adding UI

Mirage bundles [Dear ImGui](https://github.com/ocornut/imgui) through
[CImGui.jl](https://github.com/Gnimuc/CImGui.jl). Add `CImGui` to your project and
build panels alongside your canvas:

```julia
using Mirage
using CImGui

app = MirageApp("With Controls"; width = 900, height = 600)
speed = Ref(1.0f0)

run!(app) do a
    draw_background_canvas!(a) do canvas, viewport
        Mirage.translate(canvas.width / 2, canvas.height / 2)
        Mirage.rotate(time() * speed[])
        Mirage.fillcolor(Mirage.rgba(80, 160, 255))
        Mirage.fillrect(-60, -60, 120, 120)
    end

    CImGui.Begin("Controls")
    CImGui.SliderFloat("spin speed", speed, 0.0f0, 5.0f0)
    CImGui.End()
end
```

ImGui widgets read and write plain Julia `Ref`s — there is no retained widget tree
to synchronize. For docked split-pane layouts instead of floating panels, see
[`dock_layout!`](@ref) and the [Examples](examples.md).

## Running the examples

The repository ships runnable example apps under `examples/`:

```sh
git clone https://github.com/groverburger/Mirage.jl
cd Mirage.jl
julia --project=examples examples/01_minimal_app.jl
```

## The live-reload workflow

Load your code with Revise tracking it, use [`run_live!`](@ref) instead of `run!`,
and edits apply to the running app without restarting — window position and
application state intact:

```julia
using Revise
includet("myapp.jl")     # includet = Revise-tracked include
MyApp.main()             # main() uses run_live!(...)
# edit myapp.jl, save — the running window updates in place
```

Errors in your frame code are logged and skipped rather than crashing the app, so
you can fix mistakes live. See `examples/02_live_reload.jl` for a complete setup,
including making script-mode execution self-tracking with `Revise.track`.
