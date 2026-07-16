# Core Concepts

## API style

The application layer is exported: [`MirageApp`](@ref), [`run!`](@ref),
[`draw_canvas!`](@ref), [`draw_background_canvas!`](@ref), and related helpers.

Drawing calls stay qualified to avoid name conflicts:

```julia
Mirage.fillcolor(Mirage.rgba(80, 160, 255))
Mirage.fillrect(20, 20, 100, 60)
```

## Immediate mode

Mirage keeps no scene graph. Draw the current application state each frame. Dear
ImGui works the same way: widgets read and update ordinary Julia values.

## Canvases

A [`MirageApp`](@ref) owns the window and graphics contexts. Mirage draws into
offscreen canvases that ImGui displays:

- [`draw_background_canvas!`](@ref) fills the window.
- [`draw_canvas!`](@ref) fills the current ImGui content region.

Canvas callbacks receive `(canvas, viewport)`. The viewport contains mouse and
interaction state. The default projection uses pixel coordinates. For 3D, pass
`projection = :none` and configure a perspective camera.

## Rendering modes

`run!` is event-driven by default. Input wakes it automatically. Call
[`request_frame!`](@ref) after background work changes visible state.

Use `animate = true` for continuous rendering, or pass `app -> Bool` to switch at
runtime. [`stop!`](@ref) exits the loop.

## Drawing state

`Mirage.save()` and `Mirage.restore()` preserve transforms and styles:

```julia
Mirage.save()
Mirage.translate(200, 150)
Mirage.rotate(angle)
Mirage.fillrect(-40, -40, 80, 80)
Mirage.restore()
```

## 3D

Create meshes with `Mirage.create_cube`, `Mirage.create_uv_sphere`,
`Mirage.create_mesh`, or `Mirage.load_obj_mesh`. Draw them with
`Mirage.draw_mesh`. Custom shaders use `Mirage.create_shader_program` and
`Mirage.set_uniform`.

## Live reload

[`run_live!`](@ref) asks Revise to apply tracked changes before each frame. Load
Revise before packages, or use `includet` for loose scripts. Frame errors are
logged without closing the window.

## Limits

- Run the window loop on Julia's main thread.
- Run one `MirageApp` at a time.
- Render offscreen canvases before, not inside, another canvas callback.
