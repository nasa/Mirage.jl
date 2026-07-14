# Mouse input through the CanvasViewport, plus accumulating application state.
# Click and drag on the canvas to paint; use the button to clear.
#
#   julia --project=examples examples/03_paint_2d.jl

using Mirage
using CImGui

function main()
    app = MirageApp("Mirage: 2D Paint"; width = 1000, height = 700)

    # Persistent drawing state: a list of stamped points and the current brush.
    points = Tuple{Float64, Float64}[]
    brush = Ref(8.0f0)
    laid_out = Ref(false)

    # animate = false: event-driven rendering. The app repaints on input (mouse
    # movement while painting, slider drags) instead of burning GPU at 60 fps —
    # the right mode for tools that sit idle most of the time. Background tasks
    # can wake it with request_frame!(app).
    run!(app; animate = false) do a
        if !laid_out[]
            dock_layout!(a; center = "Paper", left = "Brush", left_size = 0.25)
            laid_out[] = true
        end

        CImGui.Begin("Brush")
        CImGui.SliderFloat("size", brush, 2.0f0, 40.0f0)
        if CImGui.Button("Clear")
            empty!(points)
        end
        CImGui.Text("Points: $(length(points))")
        CImGui.End()

        CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowPadding, (0.0f0, 0.0f0))
        CImGui.Begin("Paper")
        CImGui.PopStyleVar()
        draw_canvas!(a, :paper; clear_color = (0.08, 0.08, 0.11, 1.0)) do canvas, viewport
            # `viewport` reports interaction state for this canvas region.
            # `mouse_rel` is the cursor position relative to the canvas' top-left.
            if viewport.active && viewport.hovered
                push!(points, viewport.mouse_rel)
            end

            Mirage.fillcolor(Mirage.rgba(120, 220, 160))
            r = brush[]
            for (x, y) in points
                Mirage.save()
                Mirage.translate(x, y)
                Mirage.fillcircle(r)
                Mirage.restore()
            end
        end
        CImGui.End()
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
