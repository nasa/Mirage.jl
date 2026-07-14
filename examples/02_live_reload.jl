# The live-reload workflow that makes GUI development feel like ordinary Julia.
#
# Script mode (the file registers itself with Revise, see the bottom):
#
#   julia --project=examples examples/02_live_reload.jl
#
# REPL mode:
#
#   julia> using Revise
#   julia> includet("examples/02_live_reload.jl")   # includet = Revise-tracked include
#   julia> LiveReload.main()
#
# Either way: edit `scene!` below, save, and the running window updates in place —
# your window position, and any app state, are preserved across the reload.
# (Live reload requires Revise to be tracking this file. `run_live!` warns if
# Revise isn't loaded; a plain `include` without tracking won't reload.)
#
# `run_live!` installs `live_revise!` as its per-frame hook; because Mirage invokes
# your draw code with `invokelatest`, redefining `scene!` takes effect immediately.
# Errors in your frame code don't kill the app either: they are logged, frames are
# skipped, and the app recovers as soon as you save a fix.

module LiveReload

using Mirage
using CImGui

# --- Edit this function while the app runs -----------------------------------
# Try changing the color, the number of shapes, or the motion, then save.
function scene!(canvas, viewport, t)
    Mirage.fillcolor(Mirage.rgba(15, 15, 22))
    Mirage.fillrect(0, 0, canvas.width, canvas.height)

    cx, cy = canvas.width / 2, canvas.height / 2
    for i in 0:5
        Mirage.save()
        Mirage.translate(cx, cy)
        Mirage.rotate(t * 0.6 + i * (2pi / 6))
        Mirage.translate(120, 0)
        Mirage.fillcolor(Mirage.rgba(90, 200, 160))
        Mirage.fillcircle(18)
        Mirage.restore()
    end
end
# -----------------------------------------------------------------------------

function main()
    app = MirageApp("Mirage: Live Reload (edit scene!)"; width = 900, height = 600)
    start = time()
    laid_out = Ref(false)
    run_live!(app) do a
        if !laid_out[]
            dock_layout!(a; center = "Scene", top = "Live reload", top_size = 0.15)
            laid_out[] = true
        end

        CImGui.Begin("Live reload")
        CImGui.Text("Edit `scene!` in 02_live_reload.jl and save.")
        CImGui.End()

        CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowPadding, (0.0f0, 0.0f0))
        CImGui.Begin("Scene")
        CImGui.PopStyleVar()
        draw_canvas!(a, :main) do canvas, viewport
            scene!(canvas, viewport, time() - start)
        end
        CImGui.End()
    end
end

end # module LiveReload

if abspath(PROGRAM_FILE) == @__FILE__
    # Script mode: register this file with Revise so edits to `scene!` hot-reload
    # even without the REPL/includet workflow.
    import Revise
    Revise.track(LiveReload, @__FILE__)
    LiveReload.main()
end
