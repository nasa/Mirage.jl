# 3D mesh rendering on a full-window background canvas, with drag-to-orbit and
# scroll-to-zoom. Loads cube.obj from the repo root, falling back to a generated cube.
#
# This example shows the "background canvas" layout: the 3D scene fills the window
# and control panels float (and can dock) on top of it.
#
#   julia --project=examples examples/04_mesh_viewer_3d.jl

using Mirage
using CImGui

function main()
    app = MirageApp("Mirage: 3D Mesh Viewer"; width = 1000, height = 750)

    # Load a mesh (fall back to a generated cube if the .obj isn't present).
    obj_path = normpath(joinpath(@__DIR__, "..", "cube.obj"))
    mesh = isfile(obj_path) ? Mirage.load_obj_mesh(obj_path) : Mirage.create_cube(1.0)

    # Orbit-camera state.
    yaw   = Ref(0.6)
    pitch = Ref(0.5)
    dist  = Ref(6.0f0)
    last  = Ref((0.0, 0.0))

    # Scroll wheel zooms. GLFW scroll callbacks receive (window, xoff, yoff).
    set_scroll_callback!(app) do _window, _xoff, yoff
        dist[] = clamp(dist[] - Float32(yoff) * 0.5f0, 2.0f0, 20.0f0)
        request_frame!(app)
    end

    run!(app) do a
        # `projection = :none`: we set our own perspective camera below instead of
        # the default pixel-space 2D projection.
        draw_background_canvas!(a, :scene; clear_color = (0.05, 0.05, 0.08, 1.0),
                                projection = :none) do canvas, viewport
            # Drag-to-orbit: accumulate deltas while the region is held.
            if viewport.clicked
                last[] = viewport.mouse_rel
            end
            if viewport.active
                dx = viewport.mouse_rel[1] - last[][1]
                dy = viewport.mouse_rel[2] - last[][2]
                yaw[] -= dx * 0.01
                pitch[] = clamp(pitch[] + dy * 0.01, -1.4, 1.4)
                last[] = viewport.mouse_rel
            end

            r = dist[]
            cam = Float32[
                r * cos(pitch[]) * cos(yaw[]),
                r * cos(pitch[]) * sin(yaw[]),
                r * sin(pitch[])
            ]

            Mirage.glEnable(Mirage.GL_DEPTH_TEST)
            Mirage.update_perspective_projection_matrix(
                canvas.width, canvas.height, 1.0;
                near = 0.01, far = 100.0, fov = pi / 4
            )
            Mirage.lookat(cam, Float32[0, 0, 0], Float32[0, 0, 1])

            Mirage.save()
            Mirage.draw_mesh(mesh, Float32[0.4, 0.7, 1.0, 1.0])
            Mirage.restore()
        end

        CImGui.SetNextWindowPos(CImGui.ImVec2(20, 20), CImGui.ImGuiCond_FirstUseEver)
        CImGui.SetNextWindowSize(CImGui.ImVec2(340, 90), CImGui.ImGuiCond_FirstUseEver)
        CImGui.Begin("Camera")
        CImGui.Text("Drag the model to orbit; scroll to zoom.")
        CImGui.Text("distance: $(round(dist[]; digits = 1))")
        CImGui.End()
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
