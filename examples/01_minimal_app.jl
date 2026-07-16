# The smallest useful Mirage desktop app: a Dear ImGui control panel whose slider
# drives a 2D shape rendered by Mirage into a docked window.
#
#   julia --project=examples examples/01_minimal_app.jl
#
# API conventions on display here:
#   - `using Mirage` exports the app layer (MirageApp, run!, draw_canvas!, ...).
#   - The drawing API is used qualified — `Mirage.fillrect(...)`, `Mirage.save()` —
#     just like the HTML5 canvas is always accessed through `ctx.fillRect(...)`.

module MinimalApp

using Mirage
using CImGui

function main()
    app = MirageApp("Mirage: Minimal App"; width = 900, height = 600)

    # Application state is just plain Julia values. ImGui widgets take a Ref and
    # write into it; there is no retained widget tree to keep in sync.
    speed = Ref(1.0f0)
    laid_out = Ref(false)

    # Event-driven rendering is the default. This scene animates continuously, so
    # it opts in explicitly with animate = true.
    run!(app; animate = true) do a
        # Dock the canvas to fill the center with the controls on the left (runs once;
        # windows stay user-dockable afterward).
        if !laid_out[]
            dock_layout!(a; center = "Canvas", left = "Controls", left_size = 0.3)
            laid_out[] = true
        end

        CImGui.Begin("Controls")
        CImGui.Text("A square drawn by Mirage, driven by Dear ImGui.")
        CImGui.SliderFloat("spin speed", speed, 0.0f0, 5.0f0)
        CImGui.End()

        # WindowPadding 0 so the canvas sits flush inside its docked window.
        CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowPadding, (0.0f0, 0.0f0))
        CImGui.Begin("Canvas")
        CImGui.PopStyleVar()
        # draw_canvas! sizes the canvas to the window's content region and applies a
        # pixel-space 2D projection by default — draw immediately.
        draw_canvas!(a, :main) do canvas, viewport
            Mirage.save()
            Mirage.translate(canvas.width / 2, canvas.height / 2)
            Mirage.rotate(time() * speed[])
            Mirage.fillcolor(Mirage.rgba(80, 160, 255))
            Mirage.fillrect(-60, -60, 120, 120)
            Mirage.restore()
        end
        CImGui.End()
    end
end

end # module MinimalApp

if abspath(PROGRAM_FILE) == @__FILE__
    MinimalApp.main()
end
