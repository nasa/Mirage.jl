# Low-level OpenGL helpers: object generation, error checks, shader compilation, uniforms, context info.
"""
    gl_gen_one(gl_gen_fn)

Generates a single OpenGL object (buffer, vertex array, or texture) using the provided generation function.

# Arguments
- `gl_gen_fn`: The OpenGL generation function (e.g., `glGenBuffers`, `glGenVertexArrays`, `glGenTextures`).

# Returns
The ID of the generated OpenGL object.
"""
function gl_gen_one(gl_gen_fn)
    # Drain any stale errors that accumulated from previous draw calls (which lack
    # explicit error checking). glGenBuffers/Textures/VertexArrays cannot themselves
    # generate GL_INVALID_OPERATION, so any pre-existing error would be a false positive.
    while glGetError() != GL_NO_ERROR end
    id = GLuint[0]
    gl_gen_fn(1, id)
    gl_check_error("generating a buffer, array, or texture")
    id[]
end

"""
    gl_gen_buffer()

Generates a single OpenGL buffer object.

# Returns
The ID of the generated buffer object.
"""
gl_gen_buffer() = gl_gen_one(glGenBuffers)

"""
    gl_gen_vertex_array()

Generates a single OpenGL vertex array object.

# Returns
The ID of the generated vertex array object.
"""
gl_gen_vertex_array() = gl_gen_one(glGenVertexArrays)

"""
    gl_gen_texture()

Generates a single OpenGL texture object.

# Returns
The ID of the generated texture object.
"""
gl_gen_texture() = gl_gen_one(glGenTextures)

"""
    get_info_log(obj::GLuint)

Retrieves the info log for an OpenGL shader or program object.

# Arguments
- `obj`: The ID of the shader or program object.

# Returns
A string containing the info log, or an empty string if no log is available.
"""
function get_info_log(obj::GLuint)
    is_shader = glIsShader(obj)
    get_iv = is_shader == GL_TRUE ? glGetShaderiv : glGetProgramiv
    get_info = is_shader == GL_TRUE ? glGetShaderInfoLog : glGetProgramInfoLog
    len = GLint[0]
    get_iv(obj, GL_INFO_LOG_LENGTH, len)
    max_length = len[]
    if max_length > 0
        buffer = zeros(GLchar, max_length)
        size_i = GLsizei[0]
        get_info(obj, max_length, size_i, buffer)
        len = size_i[]
        unsafe_string(pointer(buffer), len)
    else
        ""
    end
end

"""
    validate_shader(shader)

Checks if an OpenGL shader compilation was successful.

# Arguments
- `shader`: The ID of the shader object.

# Returns
`true` if the shader compiled successfully, `false` otherwise.
"""
function validate_shader(shader)
    success = GLint[0]
    glGetShaderiv(shader, GL_COMPILE_STATUS, success)
    success[] == GL_TRUE
end

"""
    gl_error_message()

Retrieves the current OpenGL error message as a string.

# Returns
A string describing the OpenGL error, or an empty string if no error occurred.
"""
function gl_error_message()
    err = glGetError()
    err == GL_NO_ERROR ? "" :
        err == GL_INVALID_ENUM ? "GL_INVALID_ENUM" :
        err == GL_INVALID_VALUE ? "GL_INVALID_VALUE" :
        err == GL_INVALID_OPERATION ? "GL_INVALID_OPERATION" :
        err == GL_INVALID_FRAMEBUFFER_OPERATION ? "GL_INVALID_FRAMEBUFFER_OPERATION" :
        err == GL_OUT_OF_MEMORY ? "GL_OUT_OF_MEMORY" : "Unknown OpenGL error code $err."
end

"""
    gl_check_error(action_name="")

Checks for OpenGL errors and throws an `error` if one is found.

# Arguments
- `action_name`: An optional string describing the action being performed when the error check occurs.

# Throws
- `error`: If an OpenGL error is detected.
"""
function gl_check_error(action_name="")
    message = gl_error_message()
    if length(message) > 0
        error("OpenGL Error", isempty(action_name) ? "" : " during $action_name", ": ", message)
    end
end

"""
    create_shader(source, typ)

Creates and compiles an OpenGL shader from source.

# Arguments
- `source`: A string containing the shader source code.
- `typ`: The type of shader to create (e.g., `GL_VERTEX_SHADER`, `GL_FRAGMENT_SHADER`).

# Returns
The ID of the compiled shader.

# Throws
- `error`: If shader creation or compilation fails.
"""
function create_shader(source, typ)
    shader::GLuint = glCreateShader(typ)
    if shader == 0
        error("Error creating shader: ", gl_error_message())
    end
    glShaderSource(shader, 1, Ref(pointer(source)), C_NULL)
    glCompileShader(shader)
    !validate_shader(shader) && error("Shader compilation error: ", get_info_log(shader))
    return shader
end

"""
    create_shader_program(vertex_shader::GLuint, fragment_shader::GLuint)::GLuint

Creates an OpenGL shader program by linking a vertex and a fragment shader.

# Arguments
- `vertex_shader`: The ID of the vertex shader.
- `fragment_shader`: The ID of the fragment shader.

# Returns
The ID of the linked shader program.

# Throws
- `error`: If program creation or linking fails.
"""
function create_shader_program(vertex_shader::GLuint, fragment_shader::GLuint)::GLuint
    prog::GLuint = glCreateProgram()
    if prog == 0
        error("Error creating shader program: ", gl_error_message())
    end
    glAttachShader(prog, vertex_shader)
    gl_check_error("attaching vertex shader")
    glAttachShader(prog, fragment_shader)
    gl_check_error("attaching fragment shader")
    glLinkProgram(prog)
    status = GLint[0]
    glGetProgramiv(prog, GL_LINK_STATUS, status)
    if status[] == GL_FALSE
        log = get_info_log(prog)
        glDeleteProgram(prog)
        error("Error linking shader program: ", log)
    end
    return prog
end

"""
    create_shader_program(vertex_shader::String, fragment_shader::String)::ShaderInfo

Creates an OpenGL shader program from vertex and fragment shader source strings.

# Arguments
- `vertex_shader`: A string containing the vertex shader source code.
- `fragment_shader`: A string containing the fragment shader source code.

# Returns
A `ShaderInfo` object containing the program ID and a dictionary for uniform locations.
"""
function create_shader_program(vertex_shader::String, fragment_shader::String)::ShaderInfo
    vertex_shader_id = create_shader(vertex_shader, GL_VERTEX_SHADER)
    fragment_shader_id = create_shader(fragment_shader, GL_FRAGMENT_SHADER)
    shader = create_shader_program(vertex_shader_id, fragment_shader_id)
    glDeleteShader(vertex_shader_id)
    glDeleteShader(fragment_shader_id)
    return ShaderInfo(shader, Dict{String, GLint}())
end

global glsl_version = ""
global the_immediate_mesh = nothing

const texture_vertex_shader_source = """
    #version 330 core
    layout (location = 0) in vec3 aPos;
    layout (location = 1) in vec2 aTexCoord;

    out vec2 TexCoord;

    uniform mat4 projection;
    uniform mat4 view;
    uniform mat4 model;

    void main()
    {
        gl_Position = projection * view * model * vec4(aPos.x, aPos.y, aPos.z, 1.0);
        TexCoord = aTexCoord;
    }
"""

const texture_fragment_shader_source = """
    #version 330 core
    out vec4 FragColor;

    in vec2 TexCoord;

    uniform sampler2D textureSampler;
    uniform vec4 color;

    void main()
    {
        vec4 texColor = texture(textureSampler, TexCoord) * color;
        if (texColor.a == 0.0) { discard; }
        FragColor = texColor;
    }
"""

"""
    ShaderInfo

OpenGL shader program metadata.

# Fields
- `program_id::GLuint`: OpenGL shader program ID.
- `uniform_locations::Dict{String, GLint}`: Cached uniform locations keyed by uniform name.
"""
struct ShaderInfo
    program_id::GLuint
    uniform_locations::Dict{String, GLint}
end

"""
    initialize_shader_uniform!(shader::ShaderInfo, uniform_name::String)

Retrieves the location of a uniform variable in a shader program and stores it in the `ShaderInfo` object.

# Arguments
- `shader`: The `ShaderInfo` object representing the shader program.
- `uniform_name`: The name of the uniform variable.
"""
function initialize_shader_uniform!(shader::ShaderInfo, uniform_name::String)
    shader.uniform_locations[uniform_name] = glGetUniformLocation(shader.program_id, uniform_name)
end

"""
    set_uniform(shader::ShaderInfo, name::String, value)

Sets the value of a uniform variable in a shader program.
"""
function set_uniform(shader::ShaderInfo, name::String, value::Matrix{Float32})
    glUniformMatrix4fv(get(shader.uniform_locations, name, -1), 1, GL_FALSE, value)
end

function set_uniform(shader::ShaderInfo, name::String, value::Float32)
    glUniform1f(get(shader.uniform_locations, name, -1), value)
end

function set_uniform(shader::ShaderInfo, name::String, value::UInt32)
    glUniform1i(get(shader.uniform_locations, name, -1), value)
end

function set_uniform(shader::ShaderInfo, name::String, value::Vector{Float32})
    loc = get(shader.uniform_locations, name, -1)
    if length(value) == 3
        glUniform3fv(loc, 1, value)
    elseif length(value) == 4
        glUniform4fv(loc, 1, value)
    else
        error("Unsupported vector size for uniform")
    end
end

function set_uniform(shader::ShaderInfo, name::String, value::Int)
    glUniform1i(get(shader.uniform_locations, name, -1), value)
end

"""
    create_context_info()

Retrieves and processes OpenGL context information, including GLSL version, OpenGL version, vendor, and renderer.

# Returns
A dictionary containing OpenGL context details.

# Throws
- `error`: If the GLSL or OpenGL version strings are in an unexpected format.
"""
function create_context_info()
    global glsl_version
    glsl = split(unsafe_string(glGetString(GL_SHADING_LANGUAGE_VERSION)), ['.', ' '])
    if length(glsl) >= 2
        glsl_num = VersionNumber(parse(Int, glsl[1]), parse(Int, glsl[2]))
        glsl_version = string(glsl_num.major) * rpad(string(glsl_num.minor),2,"0")
        # Enforce minimum version for shaders if needed, e.g., 330
        # if glsl_num < v"3.3"
        #     error("OpenGL version 3.3+ required (GLSL $glsl_version found)")
        # end
    else
        error("Unexpected version number string. Please report this bug! GLSL version string: $(glsl)")
    end

    glv_str = split(unsafe_string(glGetString(GL_VERSION)), ['.', ' '])
    if length(glv_str) >= 2
        glv = VersionNumber(parse(Int, glv_str[1]), parse(Int, glv_str[2]))
    else
        error("Unexpected version number string. Please report this bug! OpenGL version string: $(glv_str)")
    end
    dict = Dict{Symbol,Any}(
        :glsl_version   => glsl_num, # Use the parsed VersionNumber
        :gl_version     => glv,
        :gl_vendor	    => unsafe_string(glGetString(GL_VENDOR)),
        :gl_renderer	=> unsafe_string(glGetString(GL_RENDERER)),
    )
    return dict # Return the dict for info printing
end

