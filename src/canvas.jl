# Offscreen render targets (Canvas) and per-frame drawing state (ContextState).
"""
    Canvas

Offscreen render target backed by an OpenGL framebuffer, color texture, and
depth/stencil renderbuffer.

# Fields
- `fbo::GLuint`: OpenGL framebuffer object ID.
- `texture::GLuint`: OpenGL texture ID for the color attachment.
- `rbo::GLuint`: OpenGL renderbuffer object ID for depth and stencil storage.
- `width::Int`: Canvas width in pixels.
- `height::Int`: Canvas height in pixels.
"""
mutable struct Canvas
    fbo::GLuint
    texture::GLuint
    rbo::GLuint # Renderbuffer Object for depth/stencil
    width::Int
    height::Int
end

"""
    create_canvas(width::Int, height::Int)

Creates a new `Canvas` object, which encapsulates an OpenGL framebuffer, texture, and renderbuffer for offscreen rendering.

# Arguments
- `width`: The width of the canvas in pixels.
- `height`: The height of the canvas in pixels.

# Returns
A `Canvas` object.

# Throws
- `@error`: If the framebuffer is not complete after creation.
"""
function create_canvas(width::Int, height::Int)
    # Generate Framebuffer
    fbo = gl_gen_one(glGenFramebuffers)
    glBindFramebuffer(GL_FRAMEBUFFER, fbo)
    gl_check_error("binding canvas FBO")

    # Create Texture Attachment
    texture = gl_gen_texture()
    glBindTexture(GL_TEXTURE_2D, texture)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, C_NULL)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0)
    gl_check_error("attaching canvas texture")

    # Create Renderbuffer for Depth/Stencil
    rbo = gl_gen_one(glGenRenderbuffers)
    glBindRenderbuffer(GL_RENDERBUFFER, rbo)
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo)
    gl_check_error("attaching canvas renderbuffer")

    # Finalize and check status
    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE
        @error "Framebuffer is not complete!"
    end

    # Unbind to return to default state
    glBindFramebuffer(GL_FRAMEBUFFER, 0)

    return Canvas(fbo, texture, rbo, width, height)
end

"""
    set_canvas(canvas::Canvas)

Sets the render target to the specified canvas. All subsequent drawing
commands will render to this canvas.

# Arguments
- `canvas`: The `Canvas` object to set as the current render target.
"""
function set_canvas(canvas::Canvas)
    glBindFramebuffer(GL_FRAMEBUFFER, canvas.fbo)
    glViewport(0, 0, canvas.width, canvas.height)
    get_context().context_stack = [ContextState()]
end

"""
    set_canvas()

Resets the render target to the main window. All subsequent drawing
commands will render to the main window.
"""
function set_canvas()
    ctx = get_context()
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glViewport(0, 0, ctx.width, ctx.height)
    get_context().context_stack = [ContextState()]
end

"""
    resize!(canvas::Canvas, width::Int, height::Int)

Resizes the canvas and its underlying texture and renderbuffer objects.

This is useful if the canvas needs to match a new window size or if a
different resolution is required for rendering effects.

# Arguments
- `canvas`: The `Canvas` object to resize.
- `width`: The new width of the canvas in pixels.
- `height`: The new height of the canvas in pixels.

# Returns
The modified `Canvas` object.
"""
function resize!(canvas::Canvas, width::Int, height::Int)
    # Ensure dimensions are valid before proceeding
    @assert width > 0 && height > 0 "Canvas dimensions must be positive"

    canvas.width = width
    canvas.height = height

    # Resize the texture attachment
    glBindTexture(GL_TEXTURE_2D, canvas.texture)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, C_NULL)
    gl_check_error("resizing canvas texture")

    # Resize the renderbuffer attachment for depth and stencil
    glBindRenderbuffer(GL_RENDERBUFFER, canvas.rbo)
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height)
    gl_check_error("resizing canvas renderbuffer")

    # Unbind objects to return to a clean state
    glBindTexture(GL_TEXTURE_2D, 0)
    glBindRenderbuffer(GL_RENDERBUFFER, 0)

    return canvas
end

"""
    destroy!(canvas::Canvas)

Frees the GPU resources associated with a Canvas.

This includes the framebuffer object (FBO), the color texture, and the
depth/stencil renderbuffer. It is essential to call this function when the
canvas is no longer needed to prevent memory leaks on the GPU.

# Arguments
- `canvas`: The `Canvas` object to destroy.
"""
function destroy!(canvas::Canvas)
    # Ensure we don't try to delete already-deleted objects
    if canvas.fbo == 0 && canvas.texture == 0 && canvas.rbo == 0
        @warn "Canvas has already been destroyed."
        return
    end

    glDeleteFramebuffers(1, [canvas.fbo])
    gl_check_error("deleting canvas FBO")

    glDeleteTextures(1, [canvas.texture])
    gl_check_error("deleting canvas texture")

    glDeleteRenderbuffers(1, [canvas.rbo])
    gl_check_error("deleting canvas RBO")

    # Set IDs to 0 to indicate that the resources have been freed
    canvas.fbo = 0
    canvas.texture = 0
    canvas.rbo = 0
end

"""
    destroy_texture!(texture_id::GLuint)

Frees the GPU resources associated with a texture.

It is the responsibility of the caller to ensure that the texture ID is no
longer used after calling this function. Consider setting your texture ID
variable to `0` to prevent accidental use of a deleted texture.

# Arguments
- `texture_id`: The ID of the texture to destroy.
"""
function destroy_texture!(texture_id::GLuint)
    if texture_id == 0
        @warn "Attempting to delete a texture with ID 0. This is a no-op."
        return
    end
    glDeleteTextures(1, [texture_id])
    gl_check_error("deleting texture")
end

"""
    ContextState

Current drawing state, including transforms, colors, stroke settings, and paths.

# Fields
- `transform::Matrix{Float32}`: Current model transformation matrix.
- `view::Matrix{Float32}`: Current view matrix.
- `projection::Matrix{Float32}`: Current projection matrix.
- `fill_color::Tuple{Float32, Float32, Float32, Float32}`: Current fill color.
- `stroke_color::Tuple{Float32, Float32, Float32, Float32}`: Current stroke color.
- `stroke_width::Float32`: Current stroke width.
- `paths::Vector{Vector{Tuple{Float32, Float32, Float32}}}`: Current path geometry.
- `current_path_index::Int`: Index of the active path.
"""
@kwdef mutable struct ContextState
    transform::Matrix{Float32} = Float32[1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1]
    view::Matrix{Float32} = Float32[1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1]
    projection::Matrix{Float32} = ortho(0f0, 800f0, 600f0, 0f0)
    fill_color::Tuple{Float32, Float32, Float32, Float32} = (1, 1, 1, 1)
    stroke_color::Tuple{Float32, Float32, Float32, Float32} = (0, 0, 0, 1)
    stroke_width::Float32 = 1
    paths::Vector{Vector{Tuple{Float32, Float32, Float32}}} = [[]]
    current_path_index::Int = 1
end

"""
    clone(x::ContextState)

Creates a deep copy of a `ContextState` object.

# Arguments
- `x`: The `ContextState` object to clone.

# Returns
A new `ContextState` object with identical, but independent, field values.
"""
function clone(x::ContextState)
    fields = fieldnames(ContextState)
    kwargs = Dict{Symbol, Any}(field => deepcopy(getfield(x, field)) for field in fields)
    return ContextState(; kwargs...)
end
