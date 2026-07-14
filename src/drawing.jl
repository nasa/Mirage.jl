# HTML5 Canvas2D-style immediate-mode drawing API: transforms, paths, shapes, text, images.
"""
    translate(dx::Number, dy::Number, dz::Number = 0)

Applies a translation to the current transformation matrix in the `ContextState`.

# Arguments
- `dx`: The translation amount along the x-axis.
- `dy`: The translation amount along the y-axis.
- `dz`: The translation amount along the z-axis (defaults to 0).
"""
function translate(dx::Number, dy::Number, dz::Number = 0)
    translate!(get_state().transform, dx, dy, dz)
end

"""
    scale(dx::Number, dy::Number, dz::Number = 1)

Applies a scaling transformation to the current transformation matrix in the `ContextState`.

# Arguments
- `dx`: The scaling factor along the x-axis.
- `dy`: The scaling factor along the y-axis.
- `dz`: The scaling factor along the z-axis (defaults to 1).
"""
function scale(dx::Number, dy::Number, dz::Number = 1)
    scale!(get_state().transform, dx, dy, dz)
end
"""
    scale(n::Number)

Applies a uniform scaling transformation to the current transformation matrix in the `ContextState`.

# Arguments
- `n`: The uniform scaling factor for all axes.
"""
scale(n::Number) = scale(n, n, n)

"""
    rotate(angle::Number)

Applies a 2D rotation around the Z-axis to the current transformation matrix in the `ContextState`.

# Arguments
- `angle`: The rotation angle in radians.
"""
function rotate(angle::Number)
    rotate!(get_state().transform, angle)
end

"""
    rotate(x::Number, y::Number, z::Number)

Applies rotations around the X, Y, and Z axes sequentially to the current transformation matrix in the `ContextState`.

# Arguments
- `x`: The rotation angle around the X-axis in radians.
- `y`: The rotation angle around the Y-axis in radians.
- `z`: The rotation angle around the Z-axis in radians.
"""
function rotate(x::Number, y::Number, z::Number)
    rotate!(get_state().transform, x, Float32[1, 0, 0])
    rotate!(get_state().transform, y, Float32[0, 1, 0])
    rotate!(get_state().transform, z, Float32[0, 0, 1])
end

"""
    lookat(args...)

Sets the view matrix in the current `ContextState` using the `view` function.

# Arguments
- `args...`: Arguments passed directly to the `view` function (e.g., `position`, `target`, `up`).
"""
function lookat(args...)
    get_state().view = view(args...)
end

"""
    beginpath()

Clears the current paths and starts a new path in the `ContextState`.
"""
function beginpath()
    get_state().paths = [[]]
    get_state().current_path_index = 1
end

"""
    moveto(x::Number, y::Number, z::Number = 0.0)

Moves the current drawing position to the specified coordinates, starting a new subpath if the current one is not empty.

# Arguments
- `x`: The x-coordinate to move to.
- `y`: The y-coordinate to move to.
- `z`: The z-coordinate to move to (defaults to 0.0).
"""
function moveto(x::Number, y::Number, z::Number = 0.0)
    state = get_state()
    if !isempty(state.paths[state.current_path_index])
        push!(state.paths, [])
        state.current_path_index += 1
    end
    push!(state.paths[state.current_path_index], (Float32(x), Float32(y), Float32(z)))
end

"""
    lineto(x::Number, y::Number, z::Number = 0.0)

Adds a line segment from the current drawing position to the specified coordinates.

# Arguments
- `x`: The x-coordinate to draw the line to.
- `y`: The y-coordinate to draw the line to.
- `z`: The z-coordinate to draw the line to (defaults to 0.0).
"""
function lineto(x::Number, y::Number, z::Number = 0.0)
    push!(get_state().paths[get_state().current_path_index], (Float32(x), Float32(y), Float32(z)))
end

"""
    closepath()

Closes the current path by adding a line segment from the current point to the starting point of the subpath.
"""
function closepath()
    state = get_state()
    current_path = state.paths[state.current_path_index]
    if !isempty(current_path)
        push!(current_path, current_path[1])
    end
end

"""
    fillcolor(tuple::Tuple{Number, Number, Number})

Sets the fill color for subsequent drawing operations using an RGB tuple. The alpha component is set to 1.

# Arguments
- `tuple`: A tuple `(r, g, b)` where `r`, `g`, and `b` are used directly as color components.
"""
function fillcolor(tuple::Tuple{Number, Number, Number})
    get_state().fill_color = (
        Float32(tuple[1]),
        Float32(tuple[2]),
        Float32(tuple[3]),
        Float32(1)
    )
end

"""
    fillcolor(tuple::Tuple{Number, Number, Number, Number})

Sets the fill color for subsequent drawing operations using an RGBA tuple.

# Arguments
- `tuple`: A tuple `(r, g, b, a)` where each value is used directly as a color component.
"""
function fillcolor(tuple::Tuple{Number, Number, Number, Number})
    get_state().fill_color = (
        Float32(tuple[1]),
        Float32(tuple[2]),
        Float32(tuple[3]),
        Float32(tuple[4])
    )
end

"""
    strokecolor(tuple::Tuple{Number, Number, Number})

Sets the stroke color for subsequent drawing operations using an RGB tuple. The alpha component is set to 1.

# Arguments
- `tuple`: A tuple `(r, g, b)` where `r`, `g`, and `b` are used directly as color components.
"""
function strokecolor(tuple::Tuple{Number, Number, Number})
    get_state().stroke_color = (
        Float32(tuple[1]),
        Float32(tuple[2]),
        Float32(tuple[3]),
        Float32(1)
    )
end

"""
    strokecolor(tuple::Tuple{Number, Number, Number, Number})

Sets the stroke color for subsequent drawing operations using an RGBA tuple.

# Arguments
- `tuple`: A tuple `(r, g, b, a)` where each value is used directly as a color component.
"""
function strokecolor(tuple::Tuple{Number, Number, Number, Number})
    get_state().stroke_color = (
        Float32(tuple[1]),
        Float32(tuple[2]),
        Float32(tuple[3]),
        Float32(tuple[4])
    )
end

"""
    rgba(r::Int, g::Int, b::Int, a::Int = 255)::Tuple{Float32, Float32, Float32, Float32}

Creates an RGBA color tuple with Float32 components (0.0-1.0) from Int components (0-255).

# Arguments
- `r`: Red component (0-255).
- `g`: Green component (0-255).
- `b`: Blue component (0-255).
- `a`: Alpha component (0-255, defaults to 255).

# Returns
A `Tuple{Float32, Float32, Float32, Float32}` representing the RGBA color.
"""
function rgba(r::Int, g::Int, b::Int, a::Int = 255)::Tuple{Float32, Float32, Float32, Float32}
    return (r / 255, g / 255, b / 255, a / 255)
end

"""
    strokewidth(w::Number)

Sets the stroke width for subsequent drawing operations.

# Arguments
- `w`: The desired stroke width.
"""
function strokewidth(w::Number)
    get_state().stroke_width = w
end

"""
    stroke()

Draws the currently defined paths as stroked lines using the current stroke color and width.
"""
function stroke()
    state::ContextState = get_state()
    all_vertices::Vector{Float32} = Float32[]
    half_stroke::Float32 = state.stroke_width / 2.0f0

    for path in state.paths
        if length(path) < 2
            continue
        end

        is_closed::Bool = path[1] == path[end]
        
        left_vertices = Vector{Tuple{Float32, Float32, Float32}}()
        right_vertices = Vector{Tuple{Float32, Float32, Float32}}()

        if is_closed
            num_points::Int = length(path)
            # Path is closed, so we loop through all points and compute miters
            for i in 1:(num_points - 1) # num_points-1 because the last point is a duplicate
                p_prev::Tuple{Float32, Float32, Float32} = (i == 1) ? path[num_points-1] : path[i-1]
                p_curr::Tuple{Float32, Float32, Float32} = path[i]
                p_next::Tuple{Float32, Float32, Float32} = path[i+1]

                v1_x::Float32, v1_y::Float32 = p_curr[1] - p_prev[1], p_curr[2] - p_prev[2]
                v2_x::Float32, v2_y::Float32 = p_next[1] - p_curr[1], p_next[2] - p_curr[2]

                len1::Float32 = sqrt(v1_x^2 + v1_y^2); v1_x /= len1; v1_y /= len1
                len2::Float32 = sqrt(v2_x^2 + v2_y^2); v2_x /= len2; v2_y /= len2

                n1_x::Float32, n1_y::Float32 = -v1_y, v1_x
                n2_x::Float32, n2_y::Float32 = -v2_y, v2_x

                miter_x::Float32, miter_y::Float32 = n1_x + n2_x, n1_y + n2_y
                miter_len_sq::Float32 = miter_x^2 + miter_y^2

                if miter_len_sq > 1e-6
                    miter_len::Float32 = sqrt(miter_len_sq)
                    miter_x /= miter_len
                    miter_y /= miter_len

                    dot_product::Float32 = n1_x * n2_x + n1_y * n2_y
                    miter_scale::Float32 = 1.0f0 / sqrt(max(0.001f0, (1.0f0 + dot_product) / 2.0f0))

                    if miter_scale > 4.0f0; miter_scale = 4.0f0; end

                    miter_dx::Float32 = miter_x * miter_scale * half_stroke
                    miter_dy::Float32 = miter_y * miter_scale * half_stroke

                    push!(left_vertices, (p_curr[1] - miter_dx, p_curr[2] - miter_dy, p_curr[3]))
                    push!(right_vertices, (p_curr[1] + miter_dx, p_curr[2] + miter_dy, p_curr[3]))
                else
                    push!(left_vertices, (p_curr[1] - n1_x * half_stroke, p_curr[2] - n1_y * half_stroke, p_curr[3]))
                    push!(right_vertices, (p_curr[1] + n1_x * half_stroke, p_curr[2] + n1_y * half_stroke, p_curr[3]))
                end
            end
            # Add the first vertex again to close the loop
            push!(left_vertices, left_vertices[1])
            push!(right_vertices, right_vertices[1])

        else # Open path
            # Process first point
            p1::Tuple{Float32, Float32, Float32} = path[1]; p2::Tuple{Float32, Float32, Float32} = path[2]
            dir_x::Float32 = p2[1] - p1[1]; dir_y::Float32 = p2[2] - p1[2]
            len::Float32 = sqrt(dir_x^2 + dir_y^2); dir_x /= len; dir_y /= len
            normal_x::Float32 = -dir_y; normal_y::Float32 = dir_x
            push!(left_vertices, (p1[1] - normal_x * half_stroke, p1[2] - normal_y * half_stroke, p1[3]))
            push!(right_vertices, (p1[1] + normal_x * half_stroke, p1[2] + normal_y * half_stroke, p1[3]))

            # Process intermediate points
            for i in 2:(length(path) - 1)
                p_prev::Tuple{Float32, Float32, Float32} = path[i-1]; p_curr::Tuple{Float32, Float32, Float32} = path[i]; p_next::Tuple{Float32, Float32, Float32} = path[i+1]
                v1_x::Float32 = p_curr[1] - p_prev[1]; v1_y::Float32 = p_curr[2] - p_prev[2]
                len1::Float32 = sqrt(v1_x^2 + v1_y^2); v1_x /= len1; v1_y /= len1
                n1_x::Float32 = -v1_y; n1_y::Float32 = v1_x

                v2_x::Float32 = p_next[1] - p_curr[1]; v2_y::Float32 = p_next[2] - p_curr[2]
                len2::Float32 = sqrt(v2_x^2 + v2_y^2); v2_x /= len2; v2_y /= len2
                n2_x::Float32 = -v2_y; n2_y::Float32 = v2_x

                miter_x::Float32 = n1_x + n2_x; miter_y::Float32 = n1_y + n2_y
                miter_len_sq::Float32 = miter_x^2 + miter_y^2
                
                if miter_len_sq > 1e-6
                    miter_len::Float32 = sqrt(miter_len_sq)
                    miter_x /= miter_len; miter_y /= miter_len
                    dot_product::Float32 = n1_x * n2_x + n1_y * n2_y
                    miter_scale::Float32 = 1.0f0 / sqrt(max(0.001f0, (1.0f0 + dot_product) / 2.0f0))
                    if miter_scale > 4.0f0; miter_scale = 4.0f0; end
                    miter_dx::Float32 = miter_x * miter_scale * half_stroke
                    miter_dy::Float32 = miter_y * miter_scale * half_stroke
                    push!(left_vertices, (p_curr[1] - miter_dx, p_curr[2] - miter_dy, p_curr[3]))
                    push!(right_vertices, (p_curr[1] + miter_dx, p_curr[2] + miter_dy, p_curr[3]))
                else
                    push!(left_vertices, (p_curr[1] - n1_x * half_stroke, p_curr[2] - n1_y * half_stroke, p_curr[3]))
                    push!(right_vertices, (p_curr[1] + n1_x * half_stroke, p_curr[2] + n1_y * half_stroke, p_curr[3]))
                end
            end

            # Process last point
            p_last::Tuple{Float32, Float32, Float32} = path[end]; p_before_last::Tuple{Float32, Float32, Float32} = path[end-1]
            dir_x = p_last[1] - p_before_last[1]; dir_y = p_last[2] - p_before_last[2]
            len = sqrt(dir_x^2 + dir_y^2); dir_x /= len; dir_y /= len
            normal_x = -dir_y; normal_y = dir_x
            push!(left_vertices, (p_last[1] - normal_x * half_stroke, p_last[2] - normal_y * half_stroke, p_last[3]))
            push!(right_vertices, (p_last[1] + normal_x * half_stroke, p_last[2] + normal_y * half_stroke, p_last[3]))
        end

        # Create triangles for both open and closed paths
        for i in 1:(length(left_vertices) - 1)
            l1::Tuple{Float32, Float32, Float32} = left_vertices[i]; r1::Tuple{Float32, Float32, Float32} = right_vertices[i]
            l2::Tuple{Float32, Float32, Float32} = left_vertices[i+1]; r2::Tuple{Float32, Float32, Float32} = right_vertices[i+1]

            append!(all_vertices, Float32[l1[1], l1[2], l1[3], 0.0f0, 0.0f0, 0.0, 0.0, 1.0])
            append!(all_vertices, Float32[r1[1], r1[2], r1[3], 1.0f0, 0.0f0, 0.0, 0.0, 1.0])
            append!(all_vertices, Float32[l2[1], l2[2], l2[3], 0.0f0, 1.0f0, 0.0, 0.0, 1.0])

            append!(all_vertices, Float32[l2[1], l2[2], l2[3], 0.0f0, 1.0f0, 0.0, 0.0, 1.0])
            append!(all_vertices, Float32[r1[1], r1[2], r1[3], 1.0f0, 0.0f0, 0.0, 0.0, 1.0])
            append!(all_vertices, Float32[r2[1], r2[2], r2[3], 1.0f0, 1.0f0, 0.0, 0.0, 1.0])
        end
    end

    if !isempty(all_vertices)
        update_mesh_vertices!(get_immediate_mesh(), all_vertices)
        draw_mesh(get_immediate_mesh(), get_context().blank_texture, [state.stroke_color...])
    end
end

"""
    fill()

Fills the currently defined paths using the current fill color.
"""
function fill()
    state::ContextState = get_state()

    for path in state.paths
        if length(path) < 3
            continue
        end

        # Simple triangulation using the first vertex as the center
        center_x::Float32, center_y::Float32, center_z::Float32 = path[1]
        vertices = Vector{Float32}()

        for i in 2:(length(path) - 1)
            x1::Float32, y1::Float32, z1::Float32 = path[i]
            x2::Float32, y2::Float32, z2::Float32 = path[i + 1]

            append!(vertices, Float32[
                center_x, center_y, center_z, 0.5f0, 0.5f0, 0.0, 0.0, 1.0, # Center vertex
                x1, y1, z1, 0.0f0, 0.0f0, 0.0, 0.0, 1.0,             # First vertex on edge
                x2, y2, z2, 1.0f0, 0.0f0, 0.0, 0.0, 1.0              # Second vertex on edge
            ])
        end

        if !isempty(vertices)
            update_mesh_vertices!(get_immediate_mesh(), vertices)
            draw_mesh(get_immediate_mesh(), get_context().blank_texture, [state.fill_color...])
        end
    end
end

"""
    rect(x::Number, y::Number, w::Number, h::Number)

Defines a rectangular path.

# Arguments
- `x`: The x-coordinate of the top-left corner of the rectangle.
- `y`: The y-coordinate of the top-left corner of the rectangle.
- `w`: The width of the rectangle.
- `h`: The height of the rectangle.
"""
function rect(x::Number, y::Number, w::Number, h::Number)
    beginpath()
    moveto(x, y)
    lineto(x + w, y)
    lineto(x + w, y + h)
    lineto(x, y + h)
    closepath()
end

"""
    circle(r::Number, x::Number = 0, y::Number = 0, segments::Int = 32)

Defines a circular path.

# Arguments
- `r`: The radius of the circle.
- `x`: Currently unused.
- `y`: Currently unused.
- `segments`: The number of line segments used to approximate the circle (defaults to 32).
"""
function circle(r::Number, x::Number = 0, y::Number = 0, segments::Int = 32)
    for i in 1:segments
        angle::Float32 = 2.0f0 * pi * (i - 1) / segments
        next_angle::Float32 = 2.0f0 * pi * i / segments
        x::Float32 = r * cos(angle)
        y::Float32 = r * sin(angle)
        if i == 0
            moveto(x, y)
        else
            lineto(x, y)
        end
    end
    closepath()
end

"""
    fillrect(x::Number, y::Number, w::Number, h::Number)

Draws a filled rectangle using the current fill color.

# Arguments
- `x`: The x-coordinate of the top-left corner of the rectangle.
- `y`: The y-coordinate of the top-left corner of the rectangle.
- `w`: The width of the rectangle.
- `h`: The height of the rectangle.
"""
function fillrect(x::Number, y::Number, w::Number, h::Number)
    drawimage(x, y, w, h, get_context().blank_texture)
end

"""
    fillcircle(radius::Number, x::Number = 0, y::Number = 0, segments::Int = 32)

Draws a filled circle using the current fill color.

# Arguments
- `radius`: The radius of the circle.
- `x`: The x-coordinate of the center of the circle (defaults to 0).
- `y`: The y-coordinate of the center of the circle (defaults to 0).
- `segments`: The number of line segments used to approximate the circle (defaults to 32).
"""
function fillcircle(radius::Number, x::Number = 0, y::Number = 0, segments::Int = 32)
    # Create triangles by connecting center to each pair of consecutive vertices
    # This creates a fan-like triangulation
    vertices = Float32[]

    for i in 1:segments
        angle::Float32 = 2.0f0 * pi * (i - 1) / segments
        next_angle::Float32 = 2.0f0 * pi * i / segments

        # Center point
        append!(vertices, 0.0f0, 0.0f0, 0.0f0)
        append!(vertices, 0.5f0, 0.5f0)
        append!(vertices, 0.0f0, 0.0f0, 1.0f0)

        # Current outer point
        append!(vertices, radius * cos(angle), radius * sin(angle), 0.0f0)
        append!(vertices, cos(angle) * 0.5f0 + 0.5f0, sin(angle) * 0.5f0 + 0.5f0)
        append!(vertices, 0.0f0, 0.0f0, 1.0f0)

        # Next outer point
        append!(vertices, radius * cos(next_angle), radius * sin(next_angle), 0.0f0)
        append!(vertices, cos(next_angle) * 0.5f0 + 0.5f0, sin(next_angle) * 0.5f0 + 0.5f0)
        append!(vertices, 0.0f0, 0.0f0, 1.0f0)
    end

    state::ContextState = get_state()
    update_mesh_vertices!(get_immediate_mesh(), vertices)
    draw_mesh(get_immediate_mesh(), get_context().blank_texture, [state.fill_color...])
end

"""
    drawimage(x::Number,
              y::Number,
              w::Number,
              h::Number,
              texture_id::GLuint)

Draws a textured rectangle.

# Arguments
- `x`: The x-coordinate of the top-left corner of the rectangle.
- `y`: The y-coordinate of the top-left corner of the rectangle.
- `w`: The width of the rectangle.
- `h`: The height of the rectangle.
- `texture_id`: The OpenGL ID of the texture to draw.
"""
function drawimage(x::Number,
                   y::Number,
                   w::Number,
                   h::Number,
                   texture_id::GLuint)
    update_mesh_vertices!(get_immediate_mesh(), Float32[
        x, y, 0.0,         0.0, 1.0,  0.0, 0.0, 1.0, # Top-left
        x, y + h, 0.0,     0.0, 0.0,  0.0, 0.0, 1.0, # Bottom-left
        x + w, y + h, 0.0, 1.0, 0.0,  0.0, 0.0, 1.0, # Bottom-right
        x, y, 0.0,         0.0, 1.0,  0.0, 0.0, 1.0, # Top-left
        x + w, y + h, 0.0, 1.0, 0.0,  0.0, 0.0, 1.0, # Bottom-right
        x + w, y, 0.0,     1.0, 1.0,  0.0, 0.0, 1.0  # Top-right
    ])
    draw_mesh(get_immediate_mesh(), texture_id)
end

# Draw text using the loaded font atlas (simplified)
"""
    text(text::String)

Draws a string of text using the loaded font atlas.

# Arguments
- `text`: The string to draw.
"""
function text(text::String)
    ctx::RenderContext = get_context()
    vertices = GLfloat[]
    x_cursor = 0f0

    # Simplified: Assume ASCII, fixed grid, no bearing/kerning
    atlas_cell_w_uv = 1.0f0 / ctx.atlas_cols
    atlas_cell_h_uv = 1.0f0 / ctx.atlas_rows

    for char in text
        if isascii(char)
            char_code = Int(char) - 32
            # Calculate grid position (row, col)
            col = char_code % ctx.atlas_cols
            row = char_code ÷ ctx.atlas_cols

            # Calculate UV coordinates for this character cell
            # UV origin (0,0) is bottom-left in OpenGL textures
            u0 = Float32(col) * atlas_cell_w_uv
            v0 = 1.0f0 - Float32(row + 1) * atlas_cell_h_uv # Y is flipped
            u1 = u0 + atlas_cell_w_uv
            v1 = v0 + atlas_cell_h_uv

            # Calculate screen position and size for this character's quad
            char_render_w = ctx.char_width
            char_render_h = ctx.char_height
            xpos = x_cursor
            ypos = 0f0 # Simple baseline alignment

            # Define quad vertices (x, y, u, v) - 6 vertices for 2 triangles
            append!(vertices, GLfloat[
                xpos, ypos, 0.0f0,                  u0, v1, 0.0f0, 0.0f0, 1.0f0, # Top-left
                xpos, ypos + char_render_h, 0.0f0,  u0, v0, 0.0f0, 0.0f0, 1.0f0, # Bottom-left
                xpos + char_render_w, ypos + char_render_h, 0.0f0, u1, v0, 0.0f0, 0.0f0, 1.0f0, # Bottom-right

                xpos, ypos, 0.0f0,                  u0, v1, 0.0f0, 0.0f0, 1.0f0, # Top-left
                xpos + char_render_w, ypos + char_render_h, 0.0f0, u1, v0, 0.0f0, 0.0f0, 1.0f0, # Bottom-right
                xpos + char_render_w, ypos, 0.0f0,  u1, v1, 0.0f0, 0.0f0, 1.0f0 # Top-right
            ])

            # Advance cursor (simplified fixed width advance)
            x_cursor += char_render_w
        else
            # Skip non-ASCII or handle differently
            x_cursor += ctx.char_width # Advance by space width
        end
    end

    if !isempty(vertices)
        update_mesh_vertices!(get_immediate_mesh(), vertices)
        draw_mesh(get_immediate_mesh(), ctx.font_texture, [get_state().fill_color...])
    end
end

"""
    get_immediate_mesh()

Retrieves or creates the global immediate mode mesh for drawing.

# Returns
The `Mesh` object for immediate mode drawing.
"""
function get_immediate_mesh()
    global the_immediate_mesh
    if the_immediate_mesh == nothing || the_immediate_mesh.vao == 0
        @debug "Creating new immediate mesh 3D"
        the_immediate_mesh = create_mesh()
    end
    return the_immediate_mesh
end

