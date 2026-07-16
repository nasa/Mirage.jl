# GUI application layer: integrates Mirage's Canvas2D/3D renderer with Dear ImGui
# (via CImGui.jl) and GLFW to build standalone desktop applications in Julia.
#
# This code was previously the separate `Oasis.jl` package; it has been absorbed
# into Mirage so that `using Mirage` provides the full desktop-GUI stack.

"""
    MirageApp

A running desktop application: an OpenGL window (GLFW), a Dear ImGui context, and
a set of named Mirage [`Canvas`](@ref) render targets that can be drawn into ImGui
windows. Construct one with the [`MirageApp(::AbstractString)`](@ref) method and
drive it with [`run!`](@ref) or [`run_live!`](@ref).
"""
mutable struct MirageApp
    window::GLFW.Window
    imgui_ctx::Ptr{Cvoid}
    canvases::Dict{Symbol, Canvas}
    dpi::Float64
    delta_time::Float64
    requested_frames::Int
    running::Bool
    docking::Bool
    clear_color::NTuple{4, Float32}
    callbacks::Vector{Any}
end

"""
    CanvasViewport

Per-frame interaction state for a canvas region drawn with [`draw_canvas!`](@ref).

# Fields
- `x`, `y`: screen position of the region's top-left corner, in pixels.
- `width`, `height`: size of the region in pixels.
- `hovered`, `focused`, `active`, `clicked`: ImGui interaction flags for the region
  (`active` is true while the mouse button is held on it).
- `mouse_pos`: cursor position in window coordinates.
- `mouse_rel`: cursor position relative to the region's top-left corner.
"""
struct CanvasViewport
    x::Float64
    y::Float64
    width::Float64
    height::Float64
    hovered::Bool
    focused::Bool
    active::Bool
    clicked::Bool
    mouse_pos::Tuple{Float64, Float64}
    mouse_rel::Tuple{Float64, Float64}
end

# Hook installed by the MirageReviseExt package extension when Revise is loaded.
# Kept as an indirection so Revise stays a weak (optional) dependency.
const _live_revise_hook = Ref{Union{Nothing, Function}}(nothing)

# Last error message from a failed frame! call, used to log each distinct error
# once instead of spamming every frame while the user fixes their code.
const _last_frame_error = Ref{Union{Nothing, String}}(nothing)

# Run the user's frame function, surviving errors: a broken frame! (e.g. a typo
# mid-live-reload) is logged and skipped rather than tearing the whole app down.
# Dear ImGui's error recovery rebalances any Begin/End left open by the exception.
function _invoke_frame!(frame!::Function, app::MirageApp)
    try
        Base.invokelatest(frame!, app)
        _last_frame_error[] = nothing
    catch e
        msg = sprint(showerror, e)
        if msg != _last_frame_error[]
            @error "Error in frame function; skipping frames until it is fixed (edits hot-reload if Revise is loaded)." exception = (e, catch_backtrace())
            _last_frame_error[] = msg
        end
        sleep(0.1) # don't spin at full speed while broken
    end
    return nothing
end

# Roboto Regular is bundled with Mirage and loaded by default so apps get a clean,
# DPI-scaled UI font out of the box (instead of Dear ImGui's tiny bitmap default).
# Roboto is licensed under the Apache License 2.0; see assets/fonts/LICENSE.
const DEFAULT_FONT_PATH = normpath(joinpath(@__DIR__, "..", "assets", "fonts", "Roboto-Regular.ttf"))

function glsl_version_and_hints!()
    @static if Sys.isapple()
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
        GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
        GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
        return "#version 150"
    else
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 0)
        return "#version 130"
    end
end

function monitor_dpi()
    dpi = 1.0
    try
        monitor = GLFW.GetPrimaryMonitor()
        xscale, yscale = GLFW.GetMonitorContentScale(monitor)
        dpi = (xscale + yscale) / 2
    catch
        dpi = 1.0
    end
    return Sys.isapple() ? 1.0 : dpi
end

function apply_full_style()
    style = CImGui.GetStyle()
    colors_ptr = reinterpret(Ptr{CImGui.ImVec4}, style.Colors)
    colors_arr = unsafe_wrap(Array{CImGui.ImVec4}, colors_ptr, Int(CImGui.ImGuiCol_COUNT); own = false)

    colors_arr[Int(CImGui.ImGuiCol_WindowBg) + 1] = CImGui.ImVec4(0.1f0, 0.1f0, 0.1f0, 0.94f0)
    colors_arr[Int(CImGui.ImGuiCol_TitleBg) + 1] = CImGui.ImVec4(0.04f0, 0.04f0, 0.04f0, 1.00f0)
    colors_arr[Int(CImGui.ImGuiCol_TitleBgActive) + 1] = CImGui.ImVec4(0.08f0, 0.08f0, 0.08f0, 1.00f0)
    colors_arr[Int(CImGui.ImGuiCol_TitleBgCollapsed) + 1] = CImGui.ImVec4(0.00f0, 0.00f0, 0.00f0, 0.51f0)
    colors_arr[Int(CImGui.ImGuiCol_FrameBg) + 1] = CImGui.ImVec4(0.157f0, 0.173f0, 0.177f0, 1.00f0)
    colors_arr[Int(CImGui.ImGuiCol_Button) + 1] = CImGui.ImVec4(0.157f0, 0.173f0, 0.177f0, 1.00f0)
    colors_arr[Int(CImGui.ImGuiCol_Header) + 1] = CImGui.ImVec4(0.075f0, 0.075f0, 0.075f0, 1.0f0)
    colors_arr[Int(CImGui.ImGuiCol_HeaderHovered) + 1] = CImGui.ImVec4(0.28f0, 0.28f0, 0.28f0, 0.80f0)
    colors_arr[Int(CImGui.ImGuiCol_HeaderActive) + 1] = CImGui.ImVec4(0.70f0, 0.70f0, 0.70f0, 1.00f0)
    colors_arr[34] = CImGui.ImVec4(0.34f0, 0.34f0, 0.34f0, 1.00f0)
    colors_arr[35] = CImGui.ImVec4(0.10f0, 0.10f0, 0.10f0, 1.00f0)
    colors_arr[36] = CImGui.ImVec4(0.30f0, 0.30f0, 0.30f0, 1.00f0)
    colors_arr[37] = CImGui.ImVec4(0.04f0, 0.04f0, 0.04f0, 1.00f0)
    colors_arr[6] = CImGui.ImVec4(0.08f0, 0.08f0, 0.08f0, 1.00f0)
    colors_arr[Int(CImGui.ImGuiCol_TabSelectedOverline) + 1] = CImGui.ImVec4(1.00f0, 0.10f0, 0.10f0, 0.00f0)
    colors_arr[38] = CImGui.ImVec4(0.10f0, 0.10f0, 0.10f0, 1.00f0)
    colors_arr[39] = CImGui.ImVec4(0.20f0, 0.20f0, 0.20f0, 1.00f0)
    colors_arr[33] = CImGui.ImVec4(0.10f0, 0.10f0, 0.10f0, 1.00f0)

    style.WindowRounding = 4.0f0
    style.TabRounding = 4.0f0
    style.TabBorderSize = 0.0f0
    return nothing
end

"""
    MirageApp(title; kwargs...)

Create a desktop application window titled `title` with an initialized OpenGL
context, Mirage render context, and Dear ImGui context.

# Keyword arguments
- `width`, `height`: initial window size in pixels (default `1200`x`800`).
- `docking`: enable ImGui docking (default `true`).
- `vsync`: enable vertical sync (default `true`).
- `alpha_bits`: framebuffer alpha bits (default `8`).
- `scale_to_monitor`: request GLFW monitor scaling (default `true`).
- `clear_color`: RGBA window clear color (default `(0.3, 0.3, 0.32, 1.0)`).
- `font_path`: TTF font for the UI. Defaults to the bundled Roboto Regular; pass a
  path to use your own, or `nothing` for Dear ImGui's built-in bitmap font.
- `font_size`: base font size in points, rasterized at `font_size * dpi` (default `18`).
- `scale_style`: scale ImGui style metrics by monitor DPI (default `true`).
- `configure_imgui!`: callback `app -> nothing` run after setup for extra ImGui config.

The app's detected DPI is available as `app.dpi` (1.0 on macOS, which handles Retina
scaling via the framebuffer). Multiply your own layout sizes by it to stay sharp on
HiDPI displays, mirroring how the widget style and font are scaled here.
"""
function MirageApp(
    title::AbstractString;
    width::Integer = 1200,
    height::Integer = 800,
    docking::Bool = true,
    vsync::Bool = true,
    alpha_bits::Integer = 8,
    scale_to_monitor::Bool = true,
    clear_color::NTuple{4, Real} = (0.3, 0.3, 0.32, 1.0),
    font_path::Union{Nothing, AbstractString} = DEFAULT_FONT_PATH,
    font_size::Real = 18,
    scale_style::Bool = true,
    configure_imgui!::Function = app -> nothing,
)
    if !GLFW.Init()
        error("Failed to initialize GLFW")
    end

    glsl_version_str = glsl_version_and_hints!()
    GLFW.WindowHint(GLFW.ALPHA_BITS, alpha_bits)
    if scale_to_monitor
        GLFW.WindowHint(0x0002200C, 1) # GLFW_SCALE_TO_MONITOR
    end

    window = GLFW.CreateWindow(width, height, String(title))
    if window.handle == C_NULL
        GLFW.Terminate()
        error("Could not create a GLFW window")
    end

    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(vsync ? 1 : 0)

    mirage_initialized = false
    imgui_ctx = C_NULL
    try
        initialize_render_context()
        mirage_initialized = true

        imgui_ctx = CImGui.CreateContext()
        io = CImGui.GetIO()
        io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_NavEnableKeyboard
        if docking
            io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
        end

        if !isdefined(CImGui, :ImGui_ImplGlfw_InitForOpenGL)
            error("ImGui_ImplGlfw_InitForOpenGL not found in CImGui namespace")
        end
        if !isdefined(CImGui, :ImGui_ImplOpenGL3_Init)
            error("ImGui_ImplOpenGL3_Init not found in CImGui namespace")
        end
        if !CImGui.ImGui_ImplGlfw_InitForOpenGL(window.handle, true)
            error("ImGui GLFW backend initialization failed")
        end
        if !CImGui.ImGui_ImplOpenGL3_Init(glsl_version_str)
            error("ImGui OpenGL3 backend initialization failed")
        end

        apply_full_style()
    catch
        try
            if imgui_ctx != C_NULL
                CImGui.DestroyContext(imgui_ctx)
            end
        catch
        end
        if mirage_initialized
            try
                cleanup_render_context()
            catch
            end
        end
        GLFW.DestroyWindow(window)
        GLFW.Terminate()
        rethrow()
    end

    app = MirageApp(
        window,
        imgui_ctx,
        Dict{Symbol, Canvas}(),
        monitor_dpi(),
        0.0,
        0,
        true,
        docking,
        Float32.(clear_color),
        Any[],
    )
    # Rasterize the UI font at font_size * dpi so text stays crisp on HiDPI displays
    # (on macOS `dpi` is 1 because the framebuffer already handles Retina scaling).
    if font_path !== nothing
        if isfile(font_path)
            CImGui.AddFontFromFileTTF(unsafe_load(CImGui.GetIO().Fonts), String(font_path), font_size * app.dpi)
        else
            @warn "Font file not found; falling back to the Dear ImGui default font." font_path
        end
    end
    if scale_style
        CImGui.ScaleAllSizes(CImGui.GetStyle(), app.dpi)
    end
    configure_imgui!(app)
    return app
end

"""
    request_frame!(app, frames = 1)

Request that `app` render at least `frames` more frames. Wakes an event-driven
event-driven loop immediately, so timers and background tasks can trigger a repaint
when data changes. GLFW input events already wake the loop automatically.
"""
function request_frame!(app::MirageApp, frames::Integer = 1)
    app.requested_frames = max(app.requested_frames, Int(frames))
    GLFW.PostEmptyEvent() # wake the loop if it is blocked waiting for events
    return app.requested_frames
end

"""
    stop!(app)

Signal `app` to exit its [`run!`](@ref) loop after the current frame. Wakes an
event-driven loop immediately, so it is safe to call from timers and other tasks.
"""
function stop!(app::MirageApp)
    app.running = false
    GLFW.SetWindowShouldClose(app.window, true)
    GLFW.PostEmptyEvent() # wake the loop if it is blocked waiting for events
    return nothing
end

"""
    get_canvas!(app, key = :main; width = 100, height = 100)

Return the Mirage [`Canvas`](@ref) registered under `key`, creating it at the
given size if it does not yet exist.
"""
function get_canvas!(app::MirageApp, key::Symbol = :main; width::Integer = 100, height::Integer = 100)
    return get!(app.canvases, key) do
        create_canvas(width, height)
    end
end

"""
    resize_canvas!(canvas, size::CImGui.ImVec2)

Resize `canvas` to match an ImGui region `size` (clamped to at least 1x1 pixels).
"""
function resize_canvas!(canvas::Canvas, size::CImGui.ImVec2)
    width = max(1, Int(trunc(size.x)))
    height = max(1, Int(trunc(size.y)))
    resize!(canvas, width, height)
    return canvas
end

"""
    destroy_canvas!(app, key)

Destroy and unregister the canvas stored under `key`, if present.
"""
function destroy_canvas!(app::MirageApp, key::Symbol)
    if haskey(app.canvases, key)
        destroy!(app.canvases[key])
        delete!(app.canvases, key)
    end
    return nothing
end

"""
    draw_canvas_image!(canvas, pos::CImGui.ImVec2, size::CImGui.ImVec2)

Blit `canvas`'s texture into the current ImGui window's draw list at `pos`/`size`.
"""
function draw_canvas_image!(canvas::Canvas, pos::CImGui.ImVec2, size::CImGui.ImVec2)
    draw_list = CImGui.GetWindowDrawList()
    CImGui.AddImage(
        draw_list,
        CImGui.ImTextureRef(UInt64(canvas.texture)),
        CImGui.ImVec2(pos.x, pos.y),
        CImGui.ImVec2(pos.x + size.x, pos.y + size.y),
        CImGui.ImVec2(0, 1),
        CImGui.ImVec2(1, 0),
    )
    return nothing
end

"""
    draw_canvas!(render!, app, key = :main; kwargs...)

Draw an interactive Mirage canvas region inside the current ImGui window. Sizes the
canvas to the available content region (or `size`), invokes `render!(canvas, viewport)`
with Mirage bound to that canvas, then blits the result. Returns the [`CanvasViewport`](@ref)
describing this frame's interaction state.

By default the canvas is ready to draw in pixel coordinates: a 2D orthographic
projection sized to the canvas is applied before `render!` runs. Pass
`projection = :none` to skip that (e.g. when setting your own perspective camera
via `Mirage.update_perspective_projection_matrix`).

# Keyword arguments
- `size`: explicit region size; defaults to the available ImGui content region.
- `label`: unique ImGui id for the interaction button.
- `reset_context`: reset Mirage's context stack before drawing (default `true`).
- `clear`: clear the canvas before drawing (default `true`).
- `clear_color`: RGBA clear color (default transparent).
- `projection`: `:ortho` (default) for a pixel-space 2D projection, or `:none`.
"""
function draw_canvas!(
    render!::Function,
    app::MirageApp,
    key::Symbol = :main;
    size = nothing,
    label::AbstractString = "##mirage_canvas_$(key)",
    reset_context::Bool = true,
    clear::Bool = true,
    clear_color::NTuple{4, Real} = (0, 0, 0, 0),
    projection::Symbol = :ortho,
)
    projection in (:ortho, :none) ||
        throw(ArgumentError("projection must be :ortho or :none, got :$projection"))
    canvas = get_canvas!(app, key)
    requested_size = size === nothing ? CImGui.GetContentRegionAvail() : size
    viewport_pos = CImGui.GetCursorScreenPos()

    CImGui.InvisibleButton(String(label), requested_size)
    item_pos = CImGui.GetItemRectMin()
    item_size = CImGui.GetItemRectSize()
    hovered = CImGui.IsItemHovered()
    focused = CImGui.IsItemFocused()
    active = CImGui.IsItemActive()
    clicked = CImGui.IsItemClicked()
    cursor_pos = GLFW.GetCursorPos(app.window)
    mouse_pos = (cursor_pos.x, cursor_pos.y)
    mouse_rel = (mouse_pos[1] - item_pos.x, mouse_pos[2] - item_pos.y)

    resize_canvas!(canvas, item_size)
    viewport = CanvasViewport(item_pos.x, item_pos.y, item_size.x, item_size.y,
                              hovered, focused, active, clicked, mouse_pos, mouse_rel)

    set_canvas(canvas)
    try
        if reset_context
            get_context().context_stack = [ContextState()]
        end
        if clear
            glViewport(0, 0, canvas.width, canvas.height)
            glClearColor(Float32.(clear_color)...)
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)
        end
        if projection === :ortho
            # Pixel-space 2D projection sized to the canvas, so render! can draw
            # immediately; opt out with projection = :none for custom 3D cameras.
            update_ortho_projection_matrix(canvas.width, canvas.height, 1.0)
        end
        Base.invokelatest(render!, canvas, viewport)
    finally
        set_canvas()
    end

    draw_canvas_image!(canvas, item_pos, item_size)
    CImGui.SetCursorScreenPos(CImGui.ImVec2(viewport_pos.x, viewport_pos.y + item_size.y))
    return viewport
end

"""
    draw_background_canvas!(render!, app, key = :main; kwargs...)

Draw a Mirage canvas that fills the entire main viewport as a full-window background,
behind any floating ImGui panels. This is the "the canvas is the app, controls float
on top" layout (maps, viewers, dashboards). Other ImGui windows drawn in the same
frame appear above it.

Takes the same keyword arguments as [`draw_canvas!`](@ref) (`size` excepted — the size
is always the full viewport) and returns the same [`CanvasViewport`](@ref).

Works with docking enabled (the default): the dockspace's passthrough central node
lets the background canvas show and receive input, while other windows remain
dockable to the edges. Alternatively, dock a regular [`draw_canvas!`](@ref) window
into a [`dock_layout!`](@ref) center for a split-pane look.
"""
function draw_background_canvas!(
    render!::Function,
    app::MirageApp,
    key::Symbol = :main;
    clear::Bool = true,
    clear_color::NTuple{4, Real} = (0, 0, 0, 0),
    reset_context::Bool = true,
    projection::Symbol = :ortho,
)
    imvp = CImGui.GetMainViewport()
    CImGui.SetNextWindowPos(unsafe_load(imvp.Pos))
    CImGui.SetNextWindowSize(unsafe_load(imvp.Size))
    window_flags = CImGui.ImGuiWindowFlags_NoTitleBar | CImGui.ImGuiWindowFlags_NoCollapse
    window_flags |= CImGui.ImGuiWindowFlags_NoResize | CImGui.ImGuiWindowFlags_NoMove
    window_flags |= CImGui.ImGuiWindowFlags_NoBringToFrontOnFocus | CImGui.ImGuiWindowFlags_NoNavFocus

    CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowRounding, 0.0f0)
    CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowBorderSize, 0.0f0)
    CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowPadding, (0.0f0, 0.0f0))
    CImGui.Begin("##mirage_background_canvas_$(key)", C_NULL, window_flags)
    CImGui.PopStyleVar(3)
    viewport = draw_canvas!(render!, app, key; reset_context, clear, clear_color, projection)
    CImGui.End()
    return viewport
end

"""
    begin_dockspace!(app; id = "MainDockSpace", menu_bar = false)

Open a full-viewport, passthrough ImGui dockspace host window. Pair with
[`end_dockspace!`](@ref).
"""
function begin_dockspace!(app::MirageApp; id::AbstractString = "MainDockSpace", menu_bar::Bool = false)
    viewport = CImGui.GetMainViewport()
    window_flags = CImGui.ImGuiWindowFlags_NoTitleBar | CImGui.ImGuiWindowFlags_NoCollapse
    if menu_bar
        window_flags |= CImGui.ImGuiWindowFlags_MenuBar
    end
    window_flags |= CImGui.ImGuiWindowFlags_NoResize | CImGui.ImGuiWindowFlags_NoMove
    window_flags |= CImGui.ImGuiWindowFlags_NoBringToFrontOnFocus | CImGui.ImGuiWindowFlags_NoNavFocus
    window_flags |= CImGui.ImGuiWindowFlags_NoBackground

    CImGui.SetNextWindowPos(unsafe_load(viewport.Pos))
    CImGui.SetNextWindowSize(unsafe_load(viewport.Size))
    CImGui.SetNextWindowViewport(unsafe_load(viewport.ID))
    CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowRounding, 0.0f0)
    CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowBorderSize, 0.0f0)
    CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowPadding, (0.0f0, 0.0f0))
    CImGui.Begin("DockSpace", C_NULL, window_flags)
    CImGui.PopStyleVar(3)

    dockspace_flags = CImGui.ImGuiDockNodeFlags_PassthruCentralNode
    dockspace_flags |= CImGui.ImGuiDockNodeFlags_AutoHideTabBar
    CImGui.DockSpace(CImGui.GetID(String(id)), (0.0f0, 0.0f0), dockspace_flags)
    return nothing
end

"""
    end_dockspace!(app)

Close the dockspace host window opened by [`begin_dockspace!`](@ref).
"""
function end_dockspace!(::MirageApp)
    CImGui.End()
    return nothing
end

"""
    dock_layout!(app; center, left=nothing, right=nothing, top=nothing, bottom=nothing,
                 left_size=0.25, right_size=0.25, top_size=0.25, bottom_size=0.25,
                 id="MainDockSpace")

Programmatically arrange named ImGui windows into the app's main dockspace: the
`center` window is docked to fill the remaining space, and any of `left`/`right`/
`top`/`bottom` are docked to that edge taking the given fraction (0–1) of the
viewport. Names must match the corresponding `CImGui.Begin` titles.

This rebuilds the layout, so call it **once** — guard it with a flag and run it at
the start of a frame (the windows themselves need not exist yet). It overrides any
layout restored from `imgui.ini`; users can still re-dock afterward.

```julia
laid_out = Ref(false)
run!(app) do a
    laid_out[] || (dock_layout!(a; center="Canvas", left="Controls", left_size=0.28); laid_out[] = true)
    # ... CImGui.Begin("Controls") ... ; CImGui.Begin("Canvas") ...
end
```
"""
function dock_layout!(
    app::MirageApp;
    center::AbstractString,
    left::Union{Nothing, AbstractString} = nothing,
    right::Union{Nothing, AbstractString} = nothing,
    top::Union{Nothing, AbstractString} = nothing,
    bottom::Union{Nothing, AbstractString} = nothing,
    left_size::Real = 0.25,
    right_size::Real = 0.25,
    top_size::Real = 0.25,
    bottom_size::Real = 0.25,
    id::AbstractString = "MainDockSpace",
)
    dockspace_id = CImGui.GetID(String(id))
    CImGui.DockBuilderRemoveNode(dockspace_id)
    CImGui.DockBuilderAddNode(dockspace_id, Int(CImGui.ImGuiDockNodeFlags_DockSpace))
    CImGui.DockBuilderSetNodeSize(dockspace_id, unsafe_load(CImGui.GetMainViewport().Size))

    remaining = Ref{UInt32}(dockspace_id)
    function dock_edge!(dir, frac, name)
        side = Ref{UInt32}(0)
        CImGui.DockBuilderSplitNode(remaining[], dir, Float32(frac), side, remaining)
        CImGui.DockBuilderDockWindow(String(name), side[])
    end

    left   === nothing || dock_edge!(CImGui.ImGuiDir_Left,  left_size,   left)
    right  === nothing || dock_edge!(CImGui.ImGuiDir_Right, right_size,  right)
    top    === nothing || dock_edge!(CImGui.ImGuiDir_Up,    top_size,    top)
    bottom === nothing || dock_edge!(CImGui.ImGuiDir_Down,  bottom_size, bottom)

    CImGui.DockBuilderDockWindow(String(center), remaining[])
    CImGui.DockBuilderFinish(dockspace_id)
    return nothing
end

# glfwWaitEventsTimeout is not wrapped by GLFW.jl; blocks until an event arrives
# or `timeout` seconds pass. Bounded blocking (instead of GLFW.WaitEvents) keeps
# Julia's scheduler breathing: timers, @async tasks, and Revise keep running.
_wait_events_timeout(timeout::Real) =
    ccall((:glfwWaitEventsTimeout, GLFW.libglfw), Cvoid, (Cdouble,), timeout)

"""
    begin_frame!(app; animate = false, idle_timeout = 0.1)

Start a new frame: pump GLFW events, clear the default framebuffer, and begin the
ImGui frame. Pair with [`end_frame!`](@ref).

When `animate` is false and no frame was requested via [`request_frame!`](@ref),
blocks waiting for input events — waking at least every `idle_timeout` seconds so
background tasks (timers, `@async`, Revise) stay responsive.
"""
function begin_frame!(
    app::MirageApp;
    animate::Bool = false,
    idle_timeout::Real = 0.1,
)
    if app.requested_frames > 0 || animate
        GLFW.PollEvents()
        app.requested_frames = max(app.requested_frames - 1, 0)
    else
        _wait_events_timeout(Float64(idle_timeout))
    end

    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glViewport(0, 0, GLFW.GetFramebufferSize(app.window)...)
    glClearColor(app.clear_color...)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)

    CImGui.ImGui_ImplOpenGL3_NewFrame()
    CImGui.ImGui_ImplGlfw_NewFrame()
    CImGui.NewFrame()
    return nothing
end

"""
    end_frame!(app)

Render the ImGui draw data, handle multi-viewport platform windows, and swap the
GLFW buffers.
"""
function end_frame!(app::MirageApp)
    CImGui.Render()
    CImGui.ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

    io = CImGui.GetIO()
    if unsafe_load(io.ConfigFlags) & CImGui.ImGuiConfigFlags_ViewportsEnable == CImGui.ImGuiConfigFlags_ViewportsEnable
        backup_current_context = GLFW.GetCurrentContext()
        CImGui.UpdatePlatformWindows()
        CImGui.RenderPlatformWindowsDefault()
        GLFW.MakeContextCurrent(backup_current_context)
    end

    GLFW.SwapBuffers(app.window)
    yield()
    return nothing
end

"""
    live_revise!(app)

Trigger a hot code reload for the live-development workflow. This is a no-op unless
the `Revise` package is loaded in the current session (which activates Mirage's
`MirageReviseExt` extension); with Revise loaded it calls `Revise.revise()` so edits
to your source are picked up while the app keeps running. Used as the default
`before_frame!` hook of [`run_live!`](@ref).
"""
function live_revise!(app::MirageApp)
    hook = _live_revise_hook[]
    hook === nothing || hook(app)
    return nothing
end

"""
    run!(frame!, app; kwargs...)

Run `app`'s main loop until the window closes or [`stop!`](@ref) is called. Each
frame calls `before_frame!(app)`, opens a dockspace (when `app.docking`), invokes
`frame!(app)` to build the UI, and presents. Always runs `cleanup!(app)` and
[`destroy!`](@ref)`(app)` on exit.

Errors thrown by `frame!` do not kill the app: each distinct error is logged once
and frames are skipped until the code is fixed — with Revise loaded (see
[`run_live!`](@ref)) you can edit the broken function and the app recovers in place.

# Keyword arguments
- `animate`: `false` (default) waits for input and renders low-rate maintenance
  frames while idle. Set it to `true` for continuous animation. Pass a function
  `app -> Bool` to decide per frame, e.g. animate only while a simulation is
  playing. Timers and background tasks should call [`request_frame!`](@ref) after
  changing visible state.
- `idle_timeout`: in event-driven mode, maximum seconds to wait before a
  maintenance frame (default `0.1`). These frames keep Julia tasks and live reload
  responsive without rendering continuously.
- `before_frame!`: callback run at the start of each frame (default no-op).
- `menu_bar`: give the dockspace host window a menu bar.
- `cleanup!`: callback run once as the loop exits.
"""
function run!(
    frame!::Function,
    app::MirageApp;
    animate::Union{Bool, Function} = false,
    before_frame!::Function = app -> nothing,
    idle_timeout::Real = 0.1,
    menu_bar::Bool = false,
    cleanup!::Function = app -> nothing,
)
    last_frame_time = time()
    try
        while app.running && !GLFW.WindowShouldClose(app.window)
            current_frame_time = time()
            app.delta_time = min(1 / 30, current_frame_time - last_frame_time)
            last_frame_time = current_frame_time

            Base.invokelatest(before_frame!, app)
            should_animate = animate isa Bool ? animate : Base.invokelatest(animate, app)::Bool
            begin_frame!(app; animate = should_animate, idle_timeout)
            if app.docking
                begin_dockspace!(app; menu_bar)
                try
                    _invoke_frame!(frame!, app)
                finally
                    end_dockspace!(app)
                end
            else
                _invoke_frame!(frame!, app)
            end
            end_frame!(app)
        end
    finally
        Base.invokelatest(cleanup!, app)
        destroy!(app)
    end
    return nothing
end

"""
    run_live!(frame!, app; kwargs...)

Like [`run!`](@ref) (same keyword arguments), but installs [`live_revise!`](@ref)
as the default `before_frame!` hook so the app hot-reloads your edits while
running. This powers the REPL workflow: start the app, use it, edit a function, see
the change without restarting.

Requires `Revise` to be loaded in the session **and** your code to be tracked by
it. Julia packages loaded with `using` or `import` after Revise are tracked
automatically. For a loose script, load it once with `Revise.includet` or register
it with `Revise.track`. Without Revise a warning is logged and the app runs without
reloading.
"""
function run_live!(
    frame!::Function,
    app::MirageApp;
    before_frame!::Function = live_revise!,
    kwargs...,
)
    if _live_revise_hook[] === nothing
        @warn """run_live! without Revise: live code reloading is disabled.
                 Run `using Revise` before loading your app package. For a loose script,
                 use `Revise.includet` or `Revise.track`.""" maxlog = 1
    end
    return run!(frame!, app; before_frame!, kwargs...)
end

"""
    set_scroll_callback!(callback, app)

Register a GLFW scroll `callback` on `app`'s window and retain it against garbage
collection. Returns the callback.
"""
function set_scroll_callback!(callback::Function, app::MirageApp)
    push!(app.callbacks, callback)
    GLFW.SetScrollCallback(app.window, callback)
    return callback
end

"""
    set_key_callback!(callback, app)

Register a GLFW key `callback` on `app`'s window and retain it against garbage
collection. Returns the callback.
"""
function set_key_callback!(callback::Function, app::MirageApp)
    push!(app.callbacks, callback)
    GLFW.SetKeyCallback(app.window, callback)
    return callback
end

"""
    set_mouse_button_callback!(callback, app)

Register a GLFW mouse-button `callback` on `app`'s window and retain it against
garbage collection. Returns the callback.
"""
function set_mouse_button_callback!(callback::Function, app::MirageApp)
    push!(app.callbacks, callback)
    GLFW.SetMouseButtonCallback(app.window, callback)
    return callback
end

"""
    destroy!(app::MirageApp)

Tear down `app`: destroy all canvases, clean up the Mirage render context, shut down
the ImGui backends and context, and destroy the GLFW window/context. Safe to call
multiple times; errors during teardown are logged, not thrown.
"""
function destroy!(app::MirageApp)
    app.running = false

    for canvas in values(app.canvases)
        try
            destroy!(canvas)
        catch e
            @error "Error while destroying Mirage canvas" exception=(e, catch_backtrace())
        end
    end
    empty!(app.canvases)

    try
        cleanup_render_context()
    catch e
        @error "Error during Mirage cleanup" exception=(e, catch_backtrace())
    end

    try
        CImGui.ImGui_ImplOpenGL3_Shutdown()
        CImGui.ImGui_ImplGlfw_Shutdown()
    catch e
        @error "Error during ImGui backend shutdown" exception=(e, catch_backtrace())
    end

    try
        CImGui.DestroyContext(app.imgui_ctx)
    catch e
        @error "Error while destroying ImGui context" exception=(e, catch_backtrace())
    end

    try
        GLFW.DestroyWindow(app.window)
        GLFW.Terminate()
    catch e
        @error "Error during GLFW cleanup" exception=(e, catch_backtrace())
    end

    return nothing
end
