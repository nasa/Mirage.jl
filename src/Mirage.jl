module Mirage

import GLFW
import CImGui
using ModernGL
using FileIO
using ImageIO # registers the PNG/JPEG/etc. loaders FileIO dispatches to
using ColorTypes: RGBA
using FixedPointNumbers: N0f8

# Implementation is split across concern-focused files; include order is the
# module's evaluation order and must be preserved (later files may annotate
# method signatures with types defined in earlier ones).
include("./matrices.jl")
include("./glutils.jl")
include("./math.jl")
include("./textures.jl")
include("./canvas.jl")
include("./default_font.jl")
include("./context.jl")
include("./drawing.jl")
include("./meshes.jl")
include("./gui.jl")

# Only the application layer is exported: these names are unique to Mirage and are
# the package's front door. The drawing, mesh, and shader APIs are public but used
# qualified — `Mirage.fillrect(...)`, `Mirage.save()` — mirroring how the HTML5
# canvas is always accessed through its context (`ctx.fillRect(...)`), and avoiding
# collisions with `Base.fill`, `Base.resize!`, and common plotting/geometry packages.
export
    MirageApp,
    CanvasViewport,
    run!,
    run_live!,
    live_revise!,
    begin_frame!,
    end_frame!,
    request_frame!,
    stop!,
    get_canvas!,
    resize_canvas!,
    destroy_canvas!,
    draw_canvas!,
    draw_background_canvas!,
    draw_canvas_image!,
    begin_dockspace!,
    end_dockspace!,
    dock_layout!,
    set_scroll_callback!,
    set_key_callback!,
    set_mouse_button_callback!

end # module Mirage
