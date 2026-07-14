# Core Concepts

Mirage.jl is built around a few core concepts designed to provide a flexible and
intuitive environment for real-time graphics and desktop applications.

## The three tiers of the API

**Tier 1 — the application layer (exported).** `using Mirage` brings in the front
door: [`MirageApp`](@ref), [`run!`](@ref), [`run_live!`](@ref), [`stop!`](@ref),
[`draw_canvas!`](@ref), [`draw_background_canvas!`](@ref), [`dock_layout!`](@ref),
input callbacks, and friends. These names are unique to Mirage and form the
lifecycle of an application.

**Tier 2 — the drawing API (qualified).** Drawing, mesh, and shader functions are
public but used qualified — `Mirage.fillrect(...)`, `Mirage.save()`,
`Mirage.draw_mesh(...)` — mirroring how the HTML5 canvas is always accessed through
its context (`ctx.fillRect(...)`). This also avoids collisions with `Base.fill`,
`Base.resize!`, and common plotting packages.

**Tier 3 — embedding (advanced).** To host Mirage inside your own GLFW/OpenGL
window and render loop, call `Mirage.initialize_render_context()` once after
creating your GL context, then use the drawing API and
`Mirage.create_canvas`/`Mirage.set_canvas` directly; pair with
`Mirage.cleanup_render_context()` at shutdown. `MirageApp` does all of this for you.

## Immediate-mode rendering

Mirage.jl uses an **immediate-mode** rendering paradigm. Graphics commands (like
`Mirage.fillrect()` or `Mirage.draw_mesh()`) are executed and sent to the GPU right
away. The library does not maintain a persistent scene graph. Instead, **you draw
everything you want to see in every frame** — your render function is effectively a
pure function of your current application state, and your application state is just
Julia variables.

The same is true of the UI: Dear ImGui is an immediate-mode GUI library, so each
frame your code says "a button here, a slider there" and ImGui handles interaction.
There are no widget trees, no callbacks to wire, and no state to synchronize.

## Apps, canvases, and viewports

A [`MirageApp`](@ref) owns the OS window, the OpenGL context, and the Dear ImGui
context. Mirage content is rendered into **canvases** — offscreen render targets —
which are then composited into the ImGui frame:

- [`draw_background_canvas!`](@ref) fills the entire window with a canvas; panels
  float (and can dock) on top. This is the "the canvas *is* the app" layout for
  maps, viewers, and dashboards.
- [`draw_canvas!`](@ref) renders a canvas inside the current ImGui window, sized to
  its content region. Combine with [`dock_layout!`](@ref) for split-pane layouts.

Both invoke your callback as `render!(canvas, viewport)`. The `canvas` carries its
pixel dimensions; the [`CanvasViewport`](@ref) reports interaction state — hover,
click, and mouse position relative to the canvas — which is how canvases respond to
the mouse (see `examples/03_paint_2d.jl`).

By default the callback runs with a **pixel-space 2D orthographic projection**
already applied. For 3D, pass `projection = :none` and set your own camera with
`Mirage.update_perspective_projection_matrix` and `Mirage.lookat`.

## Continuous vs. event-driven rendering

`run!` renders continuously by default (`animate = true`), like a game loop. For
tools that sit idle most of the time, pass `animate = false`: the loop blocks
waiting for input events and repaints only when something happens.
[`request_frame!`](@ref) and [`stop!`](@ref) wake the loop from timers and other
tasks. Pass a function `app -> Bool` to decide per frame.

## The state stack: `save()` and `restore()`

The current drawing state includes the transformation matrix (position, rotation,
scale), fill and stroke colors, and stroke width. `Mirage.save()` pushes a complete
copy of the state onto a stack; `Mirage.restore()` pops it, reverting all changes
since the matching `save()`.

This makes hierarchical drawing natural — for example, a planet and its moon:

```julia
Mirage.save()                 # save world origin state
Mirage.translate(300, 300)    # move to the planet's position
draw_planet()

Mirage.save()                 # save planet-relative state
Mirage.translate(100, 0)      # move to the moon, relative to the planet
Mirage.rotate(angle)          # spin the moon
draw_moon()

Mirage.restore()              # back to the planet's frame
Mirage.restore()              # back to the world origin
```

## The rendering pipeline: meshes and shaders

Behind the scenes, all drawing operations are ultimately `Mesh` objects drawn by a
shader:

- **`Mirage.Mesh`** holds vertex data on the GPU (positions, texture coordinates,
  normals). Helpers: `Mirage.create_cube()`, `Mirage.create_uv_sphere()`,
  `Mirage.load_obj_mesh()`, or `Mirage.create_mesh()` with custom
  `Mirage.VertexAttribute` layouts.
- **`Mirage.ShaderInfo`** holds a compiled GLSL program. Mirage's default shader
  handles position, color, and texture mapping for all built-in 2D and 3D drawing.
- **`Mirage.draw_mesh(mesh, ...)`** is the fundamental drawing call — with a
  texture, a tint color, or a custom shader plus a uniform-setup callback for full
  control (see the lit-scene demo in the test suite).

When you call a 2D function like `Mirage.fillrect()`, Mirage updates a reusable
"immediate mode" quad mesh and draws it with a blank white texture tinted by the
current fill color.

## Live reloading

[`run_live!`](@ref) installs [`live_revise!`](@ref) as a per-frame hook: when the
`Revise` package is loaded (activating Mirage's `MirageReviseExt` extension), edits
to Revise-tracked code apply to the running app. Because Mirage invokes your frame
and canvas callbacks through `invokelatest`, redefined functions take effect on the
very next frame. Errors thrown by your frame code are logged once per distinct
error and frames are skipped until you save a fix — the app never dies mid-edit.

Revise is a weak dependency: without it, `run_live!` warns and runs without
reloading.

## Limitations to know about

- **Main thread only.** GLFW requires the window and render loop on Julia's main
  thread. `request_frame!` and `stop!` are safe to call from other tasks/timers;
  other Mirage calls are not.
- **One app at a time.** Mirage keeps a single global render context; run one
  `MirageApp` per process (sequential apps are fine).
- **Nested canvas rendering** (`draw_canvas!` inside another canvas callback) is
  not supported; render offscreen canvases before the frame or in a prior pass.
