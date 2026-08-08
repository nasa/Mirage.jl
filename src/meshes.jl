"""
    VertexAttribute

Represents a single vertex attribute (e.g., position, normal, texture coordinates).

# Fields
- `location::Int`: The shader location of the attribute.
- `size::Int`: The number of components per attribute (e.g., 2 for `vec2`, 3 for `vec3`).
- `type::GLenum`: The OpenGL data type of each component (e.g., `GL_FLOAT`).
- `normalized::Bool`: Whether fixed-point data should be normalized to [0,1] or [-1,1].
- `offset::Int`: The byte offset of the attribute within the vertex data.
"""
struct VertexAttribute
    location::Int      # Shader location
    size::Int          # Number of components (e.g., 3 for vec3)
    type::GLenum       # GL_FLOAT, etc.
    normalized::Bool   # Whether to normalize fixed-point data
    offset::Int        # Byte offset within vertex
end

"""
    Mesh

GPU-resident mesh data backed by a vertex array object and vertex buffer object.

# Fields
- `vao::GLuint`: OpenGL vertex array object ID.
- `vbo::GLuint`: OpenGL vertex buffer object ID.
- `vertex_count::Int`: Number of vertices to draw.
- `draw_mode::GLenum`: OpenGL primitive type, such as `GL_TRIANGLES` or `GL_LINES`.
- `stride::Int`: Byte stride between vertices.
- `attributes::Vector{VertexAttribute}`: Vertex attribute layout used by the mesh.
"""
mutable struct Mesh
    vao::GLuint        # Vertex Array Object ID
    vbo::GLuint        # Vertex Buffer Object ID
    vertex_count::Int  # Number of vertices in the mesh
    draw_mode::GLenum  # OpenGL primitive type (e.g., GL_TRIANGLES, GL_LINES)
    stride::Int        # Byte stride between vertices
    attributes::Vector{VertexAttribute} # Vertex attribute configurations
end

get_default_attributes() = [
    VertexAttribute(0, 3, GL_FLOAT, false, 0),                    # Position (x, y, z)
    VertexAttribute(1, 2, GL_FLOAT, false, 3 * sizeof(Float32)),  # Texture coordinates (u, v)
    VertexAttribute(2, 3, GL_FLOAT, false, 5 * sizeof(Float32))   # Normal (nx, ny, nz)
]

"""
    create_mesh(vertices::Vector{T} = Float32[0, 0, 0, 0, 0, 0, 0, 0],
                attributes::Vector{VertexAttribute} = get_default_attributes();
                draw_mode::GLenum = GL_TRIANGLES) where T

Creates a new `Mesh` object and uploads vertex data to the GPU.

# Arguments
- `vertices`: A vector of vertex data. The layout should match the `attributes`.
- `attributes`: A vector of `VertexAttribute` defining the layout of the vertex data.
- `draw_mode`: The OpenGL primitive type to use when drawing the mesh (defaults to `GL_TRIANGLES`).

# Returns
A new `Mesh` object.
"""
function create_mesh(vertices::Vector{T} = Float32[0, 0, 0, 0, 0, 0, 0, 0],
                     attributes::Vector{VertexAttribute} = get_default_attributes();
                     draw_mode::GLenum = GL_TRIANGLES) where T

    # Create and bind VAO
    vao = gl_gen_vertex_array()
    glBindVertexArray(vao)

    # Create VBO for vertex data
    vbo = gl_gen_buffer()
    glBindBuffer(GL_ARRAY_BUFFER, vbo)

    # Upload vertex data
    glBufferData(
        GL_ARRAY_BUFFER,
        sizeof(vertices),
        vertices,
        GL_STATIC_DRAW
    )

    # Calculate stride (size of vertex in bytes)
    stride = sum([attr.size * sizeof(T) for attr in attributes])

    # Set up vertex attributes
    for attr in attributes
        glEnableVertexAttribArray(attr.location)
        glVertexAttribPointer(
            attr.location,
            attr.size,
            attr.type,
            attr.normalized ? GL_TRUE : GL_FALSE,
            stride,
            Ptr{Cvoid}(attr.offset)
        )
    end

    # Unbind VAO to prevent accidental modification
    glBindVertexArray(0)
    glBindBuffer(GL_ARRAY_BUFFER, 0)

    # Create and return mesh
    return Mesh(
        vao,
        vbo,
        count_vertices(attributes, vertices),
        draw_mode,
        stride,
        attributes
    )
end

"""
    draw_mesh(mesh::Mesh, texture_id::GLuint, tint_color::Vector{Float32})

Draws a mesh with a specified texture and tint color.

# Arguments
- `mesh`: The `Mesh` object to draw.
- `texture_id`: The OpenGL ID of the texture to apply.
- `tint_color`: A `Vector{Float32}` representing the RGBA tint color.
"""
function draw_mesh(mesh::Mesh, texture_id::GLuint, tint_color::Vector{Float32})
    ctx::RenderContext = get_context()
    glUseProgram(ctx.shader.program_id)
    glUniformMatrix4fv(ctx.shader.uniform_locations["projection"], 1, GL_FALSE, get_state().projection)
    glUniformMatrix4fv(ctx.shader.uniform_locations["view"], 1, GL_FALSE, get_state().view)
    glUniformMatrix4fv(ctx.shader.uniform_locations["model"], 1, GL_FALSE, get_state().transform)
    glUniform4f(ctx.shader.uniform_locations["color"], tint_color...)

    # Activate texture unit 0 and bind the texture
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, texture_id)
    glUniform1i(ctx.shader.uniform_locations["textureSampler"], 0)

    # Bind the mesh's VAO (which contains all vertex attribute configurations)
    glBindVertexArray(mesh.vao)

    # Draw the mesh
    glDrawArrays(mesh.draw_mode, 0, mesh.vertex_count)

    # Clean up state
    glBindTexture(GL_TEXTURE_2D, 0)
    glBindVertexArray(0)
    glUseProgram(0)
end

"""
    draw_mesh(mesh::Mesh, texture_id::GLuint)

Draws a mesh with a specified texture, using the current fill color from the `ContextState` as tint.

# Arguments
- `mesh`: The `Mesh` object to draw.
- `texture_id`: The OpenGL ID of the texture to apply.
"""
function draw_mesh(mesh::Mesh, texture_id::GLuint)
    draw_mesh(mesh, texture_id, Float32[get_state().fill_color...])
end

"""
    draw_mesh(mesh::Mesh, tint_color::Vector{Float32})

Draws a mesh with a specified tint color, using a blank texture.

# Arguments
- `mesh`: The `Mesh` object to draw.
- `tint_color`: A `Vector{Float32}` representing the RGBA tint color.
"""
function draw_mesh(mesh::Mesh, tint_color::Vector{Float32})
    ctx::RenderContext = get_context()
    draw_mesh(mesh, ctx.blank_texture, tint_color)
end

"""
    draw_mesh(mesh::Mesh)

Draws a mesh using a blank texture and the current fill color from the `ContextState`.

# Arguments
- `mesh`: The `Mesh` object to draw.
"""
function draw_mesh(mesh::Mesh)
    ctx::RenderContext = get_context()
    draw_mesh(mesh, ctx.blank_texture)
end

"""
    draw_mesh(mesh::Mesh, shader::ShaderInfo, setup_uniforms::Function)

Draws a mesh with a custom shader and uniforms.
"""
function draw_mesh(mesh::Mesh, shader::ShaderInfo, setup_uniforms::Function)
    glUseProgram(shader.program_id)
    setup_uniforms(shader)
    glBindVertexArray(mesh.vao)
    glDrawArrays(mesh.draw_mode, 0, mesh.vertex_count)
    glBindVertexArray(0)
    glUseProgram(0)
end

"""
    count_vertices(attributes::Vector, vertices::Vector)::Int64

Calculates the number of vertices in a vertex data vector based on the provided attributes.

# Arguments
- `attributes`: A vector of `VertexAttribute` defining the layout of the vertex data.
- `vertices`: The raw vertex data vector.

# Returns
The number of vertices.
"""
function count_vertices(attributes::Vector, vertices::Vector)::Int64
    stride::Int64 = 0
    for attr in attributes
        stride += attr.size
    end
    return div(length(vertices), stride)
end

# Update vertex data (for dynamic meshes)
"""
    update_mesh_vertices!(mesh::Mesh, vertices::Vector{Float32}, usage::GLenum = GL_DYNAMIC_DRAW)

Updates the vertex data of an existing mesh on the GPU.

# Arguments
- `mesh`: The `Mesh` object to update.
- `vertices`: The new vertex data.
- `usage`: The OpenGL usage hint for the buffer (defaults to `GL_DYNAMIC_DRAW`).
"""
function update_mesh_vertices!(mesh::Mesh, vertices::Vector{Float32}, usage::GLenum = GL_DYNAMIC_DRAW)
    glBindVertexArray(mesh.vao)
    glBindBuffer(GL_ARRAY_BUFFER, mesh.vbo)
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, usage)
    glBindBuffer(GL_ARRAY_BUFFER, 0)
    glBindVertexArray(0)
    mesh.vertex_count = count_vertices(mesh.attributes, vertices)
end

# Destroy mesh and free GPU resources
"""
    destroy!(mesh::Mesh)

Frees the GPU resources (VAO and VBO) associated with a `Mesh` object.

# Arguments
- `mesh`: The `Mesh` object to destroy.
"""
function destroy!(mesh::Mesh)
    # Delete VBO
    if mesh.vbo != 0
        glDeleteBuffers(1, [mesh.vbo])
    end

    # Delete VAO
    if mesh.vao != 0
        glDeleteVertexArrays(1, [mesh.vao])
    end

    # Clear fields to prevent accidental use after destruction
    mesh.vao = 0
    mesh.vbo = 0
    mesh.vertex_count = 0
end

# Example: Create a quad mesh using triangles
"""
    create_quad(width::Float32, height::Float32)

Creates a 2D quad mesh with position and texture coordinates.

# Arguments
- `width`: The width of the quad.
- `height`: The height of the quad.

# Returns
A `Mesh` object representing the quad.
"""
function create_quad(width::Float32, height::Float32)
    # Positions (x, y) and texture coordinates (u, v) for 6 vertices (2 triangles)
    x = width / 2
    y = height / 2
    vertices = Float32[
        -x, -y, 0, 0,
        x, -y, 1, 0,
        -x, y, 0, 1,
        x, -y, 1, 0,
        -x, y, 0, 1,
        x, y, 1, 1
    ]

    return create_mesh(vertices)
end

"""
    create_circle(radius::Float32, segments::Int = 32)

Creates a 2D circle mesh, triangulated as a fan from the center.

# Arguments
- `radius`: The radius of the circle.
- `segments`: The number of segments to use for approximating the circle (defaults to 32).

# Returns
A `Mesh` object representing the circle.
"""
function create_circle(radius::Float32, segments::Int = 32)
    # Create triangles by connecting center to each pair of consecutive vertices
    # This creates a fan-like triangulation
    vertices = Float32[]

    for i in 1:segments
        angle::Float32 = 2.0f0 * pi * (i - 1) / segments
        next_angle::Float32 = 2.0f0 * pi * i / segments

        # Center point
        append!(vertices, 0.0f0, 0.0f0)
        append!(vertices, 0.5f0, 0.5f0)

        # Current outer point
        append!(vertices, radius * cos(angle), radius * sin(angle))
        append!(vertices, cos(angle) * 0.5f0 + 0.5f0, sin(angle) * 0.5f0 + 0.5f0)

        # Next outer point
        append!(vertices, radius * cos(next_angle), radius * sin(next_angle))
        append!(vertices, cos(next_angle) * 0.5f0 + 0.5f0, sin(next_angle) * 0.5f0 + 0.5f0)
    end

    return create_mesh(vertices)
end

"""
    create_cube(size::Number = 1.0)

Creates a 3D cube mesh with position, texture coordinates, and normals for each face.

# Arguments
- `size`: The side length of the cube (defaults to 1.0).

# Returns
A `Mesh` object representing the cube.
"""
function create_cube(size::Number = 1.0)
    # Half size for centering
    s::Float32 = Float32(size / 2)

    # Vertices for all 6 faces of the cube
    # Each vertex: x, y, z, u, v, nx, ny, nz
    vertices = Float32[
        # Front face (normal: 0, 0, 1)
        -s, -s,  s, 0, 0, 0, 0, 1,
         s, -s,  s, 1, 0, 0, 0, 1,
        -s,  s,  s, 0, 1, 0, 0, 1,
         s, -s,  s, 1, 0, 0, 0, 1,
        -s,  s,  s, 0, 1, 0, 0, 1,
         s,  s,  s, 1, 1, 0, 0, 1,

        # Back face (normal: 0, 0, -1)
         s, -s, -s, 0, 0, 0, 0, -1,
        -s, -s, -s, 1, 0, 0, 0, -1,
         s,  s, -s, 0, 1, 0, 0, -1,
        -s, -s, -s, 1, 0, 0, 0, -1,
         s,  s, -s, 0, 1, 0, 0, -1,
        -s,  s, -s, 1, 1, 0, 0, -1,

        # Left face (normal: -1, 0, 0)
        -s, -s, -s, 0, 0, -1, 0, 0,
        -s, -s,  s, 1, 0, -1, 0, 0,
        -s,  s, -s, 0, 1, -1, 0, 0,
        -s, -s,  s, 1, 0, -1, 0, 0,
        -s,  s, -s, 0, 1, -1, 0, 0,
        -s,  s,  s, 1, 1, -1, 0, 0,

        # Right face (normal: 1, 0, 0)
         s, -s,  s, 0, 0, 1, 0, 0,
         s, -s, -s, 1, 0, 1, 0, 0,
         s,  s,  s, 0, 1, 1, 0, 0,
         s, -s, -s, 1, 0, 1, 0, 0,
         s,  s,  s, 0, 1, 1, 0, 0,
         s,  s, -s, 1, 1, 1, 0, 0,

        # Top face (normal: 0, 1, 0)
        -s,  s,  s, 0, 0, 0, 1, 0,
         s,  s,  s, 1, 0, 0, 1, 0,
        -s,  s, -s, 0, 1, 0, 1, 0,
         s,  s,  s, 1, 0, 0, 1, 0,
        -s,  s, -s, 0, 1, 0, 1, 0,
         s,  s, -s, 1, 1, 0, 1, 0,

        # Bottom face (normal: 0, -1, 0)
        -s, -s, -s, 0, 0, 0, -1, 0,
         s, -s, -s, 1, 0, 0, -1, 0,
        -s, -s,  s, 0, 1, 0, -1, 0,
         s, -s, -s, 1, 0, 0, -1, 0,
        -s, -s,  s, 0, 1, 0, -1, 0,
         s, -s,  s, 1, 1, 0, -1, 0
    ]

    return create_mesh(vertices)
end

"""
    create_uv_sphere(radius::Number = 1.0, u_segments::Int = 32, v_segments::Int = 16)

Creates a UV sphere mesh with position, texture coordinates, and normals.

# Arguments
- `radius`: The radius of the sphere (defaults to 1.0).
- `u_segments`: The number of segments around the equator (defaults to 32).
- `v_segments`: The number of segments along the height (defaults to 16).

# Returns
A `Mesh` object representing the UV sphere.
"""
function create_uv_sphere(radius::Number = 1.0, u_segments::Int = 32, v_segments::Int = 16)
    vertices = Float32[]
    r::Float32 = Float32(radius)
    
    for i in 0:v_segments-1
        v1_angle = Float32(i) / Float32(v_segments) * pi
        v2_angle = Float32(i + 1) / Float32(v_segments) * pi

        for j in 0:u_segments-1
            u1_angle = Float32(j) / Float32(u_segments) * 2pi
            u2_angle = Float32(j + 1) / Float32(u_segments) * 2pi

            # Vertex positions
            x1 = r * cos(u1_angle) * sin(v1_angle)
            y1 = r * cos(v1_angle)
            z1 = r * sin(u1_angle) * sin(v1_angle)

            x2 = r * cos(u2_angle) * sin(v1_angle)
            y2 = r * cos(v1_angle)
            z2 = r * sin(u2_angle) * sin(v1_angle)

            x3 = r * cos(u1_angle) * sin(v2_angle)
            y3 = r * cos(v2_angle)
            z3 = r * sin(u1_angle) * sin(v2_angle)

            x4 = r * cos(u2_angle) * sin(v2_angle)
            y4 = r * cos(v2_angle)
            z4 = r * sin(u2_angle) * sin(v2_angle)

            # Normals (for a sphere, normal is just the normalized position)
            n1 = normalize([x1, y1, z1])
            n2 = normalize([x2, y2, z2])
            n3 = normalize([x3, y3, z3])
            n4 = normalize([x4, y4, z4])

            # UV coordinates
            tex_u1 = Float32(j) / Float32(u_segments)
            tex_u2 = Float32(j + 1) / Float32(u_segments)
            tex_v1 = Float32(i) / Float32(v_segments)
            tex_v2 = Float32(i + 1) / Float32(v_segments)

            # First triangle
            if i > 0
                append!(vertices, [x1, y1, z1, tex_u1, tex_v1, n1...])
                append!(vertices, [x2, y2, z2, tex_u2, tex_v1, n2...])
                append!(vertices, [x3, y3, z3, tex_u1, tex_v2, n3...])
            end

            # Second triangle
            if i < v_segments - 1
                append!(vertices, [x2, y2, z2, tex_u2, tex_v1, n2...])
                append!(vertices, [x4, y4, z4, tex_u2, tex_v2, n4...])
                append!(vertices, [x3, y3, z3, tex_u1, tex_v2, n3...])
            end
        end
    end

    return create_mesh(vertices)
end

"""
    load_obj_mesh(filepath::String)

Loads a 3D mesh from an OBJ file. Supports positions, texture coordinates, and normals.

# Arguments
- `filepath`: The path to the OBJ file.

# Returns
A `Mesh` object representing the loaded model.
"""
function load_obj_mesh(filepath::String)
    vertices = Float32[]
    positions = Vector{Vector{Float32}}()
    texcoords = Vector{Vector{Float32}}()
    normals = Vector{Vector{Float32}}()

    open(filepath, "r") do f
        for line in eachline(f)
            parts = split(line)
            if isempty(parts) continue end

            if parts[1] == "v"
                push!(positions, [parse(Float32, p) for p in parts[2:4]])
            elseif parts[1] == "vt"
                push!(texcoords, [parse(Float32, p) for p in parts[2:3]])
            elseif parts[1] == "vn"
                push!(normals, [parse(Float32, p) for p in parts[2:4]])
            elseif parts[1] == "f"
                # Triangulate faces (supports N-gons)
                face_vertices_indices = []
                for i in 2:length(parts)
                    v_idx, vt_idx, vn_idx = 0, 0, 0
                    v_vt_vn = split(parts[i], '/')

                    # Always have a vertex index
                    v_idx = parse(Int, v_vt_vn[1])

                    if length(v_vt_vn) == 2
                        # Format: v/vt
                        vt_idx = parse(Int, v_vt_vn[2])
                    elseif length(v_vt_vn) == 3
                        # Format: v/vt/vn or v//vn
                        if !isempty(v_vt_vn[2])
                            vt_idx = parse(Int, v_vt_vn[2])
                        end
                        vn_idx = parse(Int, v_vt_vn[3])
                    end
                    push!(face_vertices_indices, (v_idx, vt_idx, vn_idx))
                end

                # Fan triangulation
                if length(face_vertices_indices) >= 3
                    v1_idx, vt1_idx, vn1_idx = face_vertices_indices[1]
                    pos1 = positions[v1_idx]
                    tc1 = (vt1_idx > 0 && !isempty(texcoords)) ? texcoords[vt1_idx] : [0.0f0, 0.0f0]
                    n1 = (vn1_idx > 0 && !isempty(normals)) ? normals[vn1_idx] : [0.0f0, 0.0f0, 0.0f0]

                    for i in 2:(length(face_vertices_indices) - 1)
                        v2_idx, vt2_idx, vn2_idx = face_vertices_indices[i]
                        pos2 = positions[v2_idx]
                        tc2 = (vt2_idx > 0 && !isempty(texcoords)) ? texcoords[vt2_idx] : [0.0f0, 0.0f0]
                        n2 = (vn2_idx > 0 && !isempty(normals)) ? normals[vn2_idx] : [0.0f0, 0.0f0, 0.0f0]

                        v3_idx, vt3_idx, vn3_idx = face_vertices_indices[i+1]
                        pos3 = positions[v3_idx]
                        tc3 = (vt3_idx > 0 && !isempty(texcoords)) ? texcoords[vt3_idx] : [0.0f0, 0.0f0]
                        n3 = (vn3_idx > 0 && !isempty(normals)) ? normals[vn3_idx] : [0.0f0, 0.0f0, 0.0f0]

                        append!(vertices, pos1..., tc1..., n1...)
                        append!(vertices, pos2..., tc2..., n2...)
                        append!(vertices, pos3..., tc3..., n3...)
                    end
                end
            end
        end
    end
    
    return create_mesh(vertices)
end
