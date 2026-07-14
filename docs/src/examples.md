# Examples

The repository ships complete, runnable example apps under
[`examples/`](https://github.com/groverburger/Mirage.jl/tree/master/examples). From
a clone of the repository:

```sh
julia --project=examples examples/01_minimal_app.jl
```

| File | What it shows |
|------|---------------|
| `01_minimal_app.jl`    | Smallest useful app: an ImGui control panel driving a 2D canvas in a docked layout. |
| `02_live_reload.jl`    | The `run_live!` + Revise hot-reload workflow (script mode and REPL mode). |
| `03_paint_2d.jl`       | Mouse input via `CanvasViewport`, accumulating state, and event-driven rendering (`animate = false`). |
| `04_mesh_viewer_3d.jl` | 3D mesh rendering on a background canvas with drag-to-orbit and scroll-to-zoom. |

The sections below are shorter annotated snippets of the same patterns.

## A docked split-pane layout

[`dock_layout!`](@ref) arranges named ImGui windows programmatically: the canvas
fills the center, panels take the edges, and everything stays user-dockable.

```julia
using Mirage
using CImGui

app = MirageApp("Docked Layout"; width = 1000, height = 700)
laid_out = Ref(false)

run!(app) do a
    if !laid_out[]   # build the layout once, at the start of the first frame
        dock_layout!(a; center = "Viewport", left = "Settings", left_size = 0.25)
        laid_out[] = true
    end

    CImGui.Begin("Settings")
    CImGui.Text("Controls go here.")
    CImGui.End()

    CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowPadding, (0.0f0, 0.0f0))
    CImGui.Begin("Viewport")
    CImGui.PopStyleVar()
    draw_canvas!(a, :scene) do canvas, viewport
        Mirage.fillcolor(Mirage.rgba(80, 160, 255))
        Mirage.fillcircle(60, canvas.width / 2, canvas.height / 2)
    end
    CImGui.End()
end
```

## 2D drawing: transforms, paths, and text

Inside any canvas callback, the drawing API works like the HTML5 Canvas:

```julia
draw_canvas!(app, :scene) do canvas, viewport
    # Shapes with the transform stack
    Mirage.save()
    Mirage.translate(200, 150)
    Mirage.rotate(pi / 8)
    Mirage.fillcolor(Mirage.rgba(255, 100, 100))
    Mirage.fillrect(-50, -25, 100, 50)
    Mirage.restore()

    # Paths
    Mirage.save()
    Mirage.beginpath()
    Mirage.moveto(50, 300)
    Mirage.lineto(150, 250)
    Mirage.lineto(250, 320)
    Mirage.strokewidth(4)
    Mirage.strokecolor(Mirage.rgba(64, 128, 255))
    Mirage.stroke()
    Mirage.restore()

    # Text
    Mirage.save()
    Mirage.translate(50, 50)
    Mirage.scale(2)
    Mirage.fillcolor(Mirage.rgba(255, 255, 0))
    Mirage.text("Hello from Mirage!")
    Mirage.restore()
end
```

## Textures and images

```julia
texture = Mirage.load_texture("photo.jpg")   # load once, outside the frame loop

draw_canvas!(app, :scene) do canvas, viewport
    Mirage.drawimage(10, 10, 320, 240, texture)
end
```

## 3D: meshes and cameras

For 3D, opt out of the default 2D projection and set up a perspective camera:

```julia
mesh = Mirage.load_obj_mesh("model.obj")     # or Mirage.create_cube(1.0)

run!(app) do a
    draw_background_canvas!(a, :scene; projection = :none,
                            clear_color = (0.05, 0.05, 0.08, 1.0)) do canvas, viewport
        Mirage.glEnable(Mirage.GL_DEPTH_TEST)
        Mirage.update_perspective_projection_matrix(
            canvas.width, canvas.height, 1.0; near = 0.01, far = 100.0, fov = pi / 4)
        Mirage.lookat(Float32[4, 4, 3], Float32[0, 0, 0], Float32[0, 0, 1])

        Mirage.save()
        Mirage.rotate(time() * 0.5, time() * 0.3, 0.0)
        Mirage.draw_mesh(mesh, Float32[0.4, 0.7, 1.0, 1.0])
        Mirage.restore()
    end
end
```

The 3D transform stack works exactly like the 2D one — `Mirage.translate`,
`Mirage.rotate`, and `Mirage.scale` accept 3D arguments, and `Mirage.draw_mesh`
draws with the current model transform, view, and projection. For custom lighting
and materials, pass your own shader:
`Mirage.draw_mesh(mesh, shader, s -> Mirage.set_uniform(s, "lightPos", light))` —
see the lit-scene demo in `test/MirageTestDemos.jl` for a complete Phong example.
