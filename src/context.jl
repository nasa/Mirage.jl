# The global RenderContext: shared GPU resources and the active drawing-state stack.
"""
    RenderContext

Global rendering resources and drawing state for the active OpenGL context.

# Fields
- `shader::ShaderInfo`: Default texture shader.
- `blank_texture::GLuint`: One-pixel white texture used for untextured drawing.
- `font_texture::GLuint`: Texture atlas used by `text`.
- `char_width::Float32`: Fixed-width font cell width in pixels.
- `char_height::Float32`: Fixed-width font cell height in pixels.
- `atlas_cols::Int`: Number of columns in the font atlas.
- `atlas_rows::Int`: Number of rows in the font atlas.
- `context_stack::Vector{ContextState}`: Saved drawing states.
- `width::Int`: Current window or framebuffer width.
- `height::Int`: Current window or framebuffer height.
- `dpi_scaling::Number`: Framebuffer-to-window scaling factor.
"""
mutable struct RenderContext
    shader::ShaderInfo
    blank_texture::GLuint
    font_texture::GLuint
    char_width::Float32  # Assuming fixed width font atlas grid cell
    char_height::Float32 # Assuming fixed height font atlas grid cell
    atlas_cols::Int      # Number of columns in font atlas grid
    atlas_rows::Int      # Number of rows in font atlas grid
    context_stack::Vector{ContextState}
    width::Int
    height::Int
    dpi_scaling::Number

    """
    RenderContext()

Constructs a new `RenderContext` object, initializing OpenGL shaders, textures, and context state.

# Returns
A new `RenderContext` instance.
"""
    function RenderContext()::RenderContext
        shader = create_shader_program(
            texture_vertex_shader_source,
            texture_fragment_shader_source
        )

        initialize_shader_uniform!(shader, "projection")
        initialize_shader_uniform!(shader, "view")
        initialize_shader_uniform!(shader, "model")
        initialize_shader_uniform!(shader, "textureSampler")
        initialize_shader_uniform!(shader, "color")

        blank_texture = gl_gen_texture()
        font_texture = load_texture(map(x -> x == 1 ? RGBA(1, 1, 1, 1) : RGBA(0, 0, 0, 0), default_font))

        glBindTexture(GL_TEXTURE_2D, blank_texture)
        white_pixel = UInt8[255, 255, 255, 255]
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, white_pixel)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
        glBindTexture(GL_TEXTURE_2D, 0)
        char_width, char_height = 8.0f0, 16.0f0 # Pixel dimensions of a character cell
        atlas_cols, atlas_rows = 16, 6

        return new(
            shader,
            blank_texture,
            font_texture,
            char_width, char_height,
            atlas_cols, atlas_rows,
            [ContextState()],
            800, 600,
            1.0
        )
    end
end

const render_context = Ref{RenderContext}()

"""
    cleanup_render_context(ctx::RenderContext = get_context())

Cleans up OpenGL resources associated with a `RenderContext`, including shader programs and textures.

# Arguments
- `ctx`: The `RenderContext` to clean up (defaults to the current context).
"""
function cleanup_render_context(ctx::RenderContext = get_context())
    glDeleteProgram(ctx.shader.program_id)
    glDeleteTextures(1, [ctx.blank_texture])
    glDeleteTextures(1, [ctx.font_texture])
    global the_immediate_mesh = nothing
end

"""
    save()

Pushes a copy of the current `ContextState` onto the context stack, effectively saving the current drawing state.
"""
save() = push!(get_context().context_stack, clone(get_context().context_stack[end]))

"""
    restore()

Pops the last saved `ContextState` from the context stack, restoring the previous drawing state.
"""
restore() = pop!(get_context().context_stack)

"""
    get_context()

Retrieves the global `RenderContext` instance.

# Returns
The global `RenderContext`.
"""
get_context() = render_context[]

"""
    get_state()

Retrieves the current `ContextState` from the top of the context stack.

# Returns
The current `ContextState`.
"""
get_state() = get_context().context_stack[end]


"""
    set_render_context(ctx::RenderContext)

Sets the global `RenderContext`. Part of the embedding API: use this together with
[`initialize_render_context`](@ref) when hosting Mirage inside your own GLFW/OpenGL
window and render loop instead of a `MirageApp`.

# Arguments
- `ctx`: The `RenderContext` to set as global.
"""
function set_render_context(ctx::RenderContext)
    render_context[] = ctx
end

"""
    initialize_render_context()

Initializes the global `RenderContext`. Call this once after creating an OpenGL
context to use Mirage's drawing API inside your own window and render loop (the
embedding path — `MirageApp` calls it for you). Pair with
[`cleanup_render_context`](@ref) at shutdown.
"""
function initialize_render_context()
    set_render_context(RenderContext())
end

"""
    clear()

Clears the color, depth, and stencil buffers of the current OpenGL render target.
"""
function clear()
    glClearColor(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)
end
