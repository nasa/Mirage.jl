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
    request_frame!,
    stop!,
    draw_canvas!,
    draw_background_canvas!,
    dock_layout!

end # module Mirage
