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
    get_state().stroke_width = Float32(w)
end

const Point3 = NTuple{3, Float32}
const StrokeEdges = Tuple{Vector{Point3}, Vector{Point3}}

function stroke_cap(point::Point3, edge_start::Point3, edge_end::Point3,
                    half_width::Float32)::Tuple{Point3, Point3}
    direction_x::Float32 = edge_end[1] - edge_start[1]
    direction_y::Float32 = edge_end[2] - edge_start[2]
    direction_length::Float32 = hypot(direction_x, direction_y)
    normal_x::Float32 = -direction_y / direction_length
    normal_y::Float32 = direction_x / direction_length

    left::Point3 = (point[1] - normal_x * half_width,
                    point[2] - normal_y * half_width,
                    point[3])
    right::Point3 = (point[1] + normal_x * half_width,
                     point[2] + normal_y * half_width,
                     point[3])
    return left, right
end

function stroke_join(previous::Point3, current::Point3, next::Point3,
                     half_width::Float32)::Tuple{Point3, Point3}
    previous_x::Float32 = current[1] - previous[1]
    previous_y::Float32 = current[2] - previous[2]
    previous_length::Float32 = hypot(previous_x, previous_y)
    previous_x /= previous_length
    previous_y /= previous_length

    next_x::Float32 = next[1] - current[1]
    next_y::Float32 = next[2] - current[2]
    next_length::Float32 = hypot(next_x, next_y)
    next_x /= next_length
    next_y /= next_length

    previous_normal_x::Float32 = -previous_y
    previous_normal_y::Float32 = previous_x
    next_normal_x::Float32 = -next_y
    next_normal_y::Float32 = next_x

    miter_x::Float32 = previous_normal_x + next_normal_x
    miter_y::Float32 = previous_normal_y + next_normal_y
    miter_length_squared::Float32 = miter_x^2 + miter_y^2

    offset_x::Float32 = previous_normal_x * half_width
    offset_y::Float32 = previous_normal_y * half_width
    if miter_length_squared > 1.0f-6
        miter_length::Float32 = sqrt(miter_length_squared)
        miter_x /= miter_length
        miter_y /= miter_length

        normal_dot_product::Float32 = +(
            previous_normal_x * next_normal_x,
            previous_normal_y * next_normal_y
        )
        miter_scale::Float32 = min(
            4.0f0,
            inv(sqrt(max(0.001f0, (1.0f0 + normal_dot_product) / 2.0f0)))
        )
        offset_x = miter_x * miter_scale * half_width
        offset_y = miter_y * miter_scale * half_width
    end

    left::Point3 = (current[1] - offset_x, current[2] - offset_y, current[3])
    right::Point3 = (current[1] + offset_x, current[2] + offset_y, current[3])
    return left, right
end

function stroke_edges(path::Vector{Point3}, half_width::Float32)::StrokeEdges
    is_closed::Bool = path[1] == path[end]
    point_count::Int = is_closed ? length(path) - 1 : length(path)
    left::Vector{Point3} = Point3[]
    right::Vector{Point3} = Point3[]

    if is_closed
        for index::Int in 1:point_count
            previous::Point3 = path[mod1(index - 1, point_count)]
            current::Point3 = path[index]
            next::Point3 = path[mod1(index + 1, point_count)]
            left_point::Point3, right_point::Point3 = stroke_join(
                previous, current, next, half_width
            )
            push!(left, left_point)
            push!(right, right_point)
        end
        push!(left, left[1])
        push!(right, right[1])
    else
        first_left::Point3, first_right::Point3 = stroke_cap(
            path[1], path[1], path[2], half_width
        )
        push!(left, first_left)
        push!(right, first_right)

        for index::Int in 2:(point_count - 1)
            left_point::Point3, right_point::Point3 = stroke_join(
                path[index - 1], path[index], path[index + 1], half_width
            )
            push!(left, left_point)
            push!(right, right_point)
        end

        last_left::Point3, last_right::Point3 = stroke_cap(
            path[end], path[end - 1], path[end], half_width
        )
        push!(left, last_left)
        push!(right, last_right)
    end

    return left, right
end

function append_stroke_vertex!(vertices::Vector{Float32}, point::Point3,
                               u::Float32, v::Float32)::Nothing
    append!(vertices, Float32[point[1], point[2], point[3], u, v, 0, 0, 1])
    return nothing
end

function append_stroke_quad!(vertices::Vector{Float32}, left_start::Point3,
                             right_start::Point3, left_end::Point3,
                             right_end::Point3)::Nothing
    append_stroke_vertex!(vertices, left_start, 0.0f0, 0.0f0)
    append_stroke_vertex!(vertices, right_start, 1.0f0, 0.0f0)
    append_stroke_vertex!(vertices, left_end, 0.0f0, 1.0f0)
    append_stroke_vertex!(vertices, left_end, 0.0f0, 1.0f0)
    append_stroke_vertex!(vertices, right_start, 1.0f0, 0.0f0)
    append_stroke_vertex!(vertices, right_end, 1.0f0, 1.0f0)
    return nothing
end

"""
    stroke()

Draws the currently defined paths as stroked lines using the current stroke color and width.
"""
function stroke()
    state::ContextState = get_state()
    all_vertices::Vector{Float32} = Float32[]
    half_stroke::Float32 = state.stroke_width / 2.0f0

    for path::Vector{Point3} in state.paths
        length(path) < 2 && continue

        left::Vector{Point3}, right::Vector{Point3} = stroke_edges(path, half_stroke)
        for index::Int in 1:(length(left) - 1)
            append_stroke_quad!(
                all_vertices, left[index], right[index],
                left[index + 1], right[index + 1]
            )
        end
    end

    if !isempty(all_vertices)
        update_mesh_vertices!(get_immediate_mesh(), all_vertices)
        color::Vector{Float32} = Float32[state.stroke_color...]
        draw_mesh(get_immediate_mesh(), get_context().blank_texture, color)
    end
end

"""
    fill()

Fills the currently defined paths using the current fill color.
"""
function fill()
    state::ContextState = get_state()

    for path::Vector{Point3} in state.paths
        if length(path) < 3
            continue
        end

        center_x::Float32, center_y::Float32, center_z::Float32 = path[1]
        vertices::Vector{Float32} = Float32[]

        for index::Int in 2:(length(path) - 1)
            x1::Float32, y1::Float32, z1::Float32 = path[index]
            x2::Float32, y2::Float32, z2::Float32 = path[index + 1]

            append!(vertices, Float32[
                center_x, center_y, center_z, 0.5f0, 0.5f0, 0.0f0, 0.0f0, 1.0f0,
                x1, y1, z1, 0.0f0, 0.0f0, 0.0f0, 0.0f0, 1.0f0,
                x2, y2, z2, 1.0f0, 0.0f0, 0.0f0, 0.0f0, 1.0f0
            ])
        end

        if !isempty(vertices)
            update_mesh_vertices!(get_immediate_mesh(), vertices)
            color::Vector{Float32} = Float32[state.fill_color...]
            draw_mesh(get_immediate_mesh(), get_context().blank_texture, color)
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
    circle(radius::Number, center_x::Number = 0, center_y::Number = 0,
           segments::Int = 32)

Defines a circular path.

# Arguments
- `radius`: The radius of the circle.
- `center_x`: The x-coordinate of the center.
- `center_y`: The y-coordinate of the center.
- `segments`: The number of line segments used to approximate the circle (defaults to 32).
"""
function circle(radius::Number, center_x::Number = 0, center_y::Number = 0,
                segments::Int = 32)
    for index::Int in 1:segments
        angle::Float32 = 2.0f0 * Float32(pi) * (index - 1) / segments
        point_x::Float32 = Float32(center_x + radius * cos(angle))
        point_y::Float32 = Float32(center_y + radius * sin(angle))
        if index == 1
            moveto(point_x, point_y)
        else
            lineto(point_x, point_y)
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
    fillcircle(radius::Number, center_x::Number = 0, center_y::Number = 0,
               segments::Int = 32)

Draws a filled circle using the current fill color.

# Arguments
- `radius`: The radius of the circle.
- `center_x`: The x-coordinate of the center of the circle (defaults to 0).
- `center_y`: The y-coordinate of the center of the circle (defaults to 0).
- `segments`: The number of line segments used to approximate the circle (defaults to 32).
"""
function fillcircle(radius::Number, center_x::Number = 0, center_y::Number = 0,
                    segments::Int = 32)
    vertices::Vector{Float32} = Float32[]
    radius32::Float32 = Float32(radius)
    center_x32::Float32 = Float32(center_x)
    center_y32::Float32 = Float32(center_y)

    for index::Int in 1:segments
        angle::Float32 = 2.0f0 * Float32(pi) * (index - 1) / segments
        next_angle::Float32 = 2.0f0 * Float32(pi) * index / segments
        point_x::Float32 = center_x32 + radius32 * cos(angle)
        point_y::Float32 = center_y32 + radius32 * sin(angle)
        next_x::Float32 = center_x32 + radius32 * cos(next_angle)
        next_y::Float32 = center_y32 + radius32 * sin(next_angle)

        append!(vertices, Float32[
            center_x32, center_y32, 0.0f0, 0.5f0, 0.5f0, 0.0f0, 0.0f0, 1.0f0,
            point_x, point_y, 0.0f0,
            cos(angle) * 0.5f0 + 0.5f0, sin(angle) * 0.5f0 + 0.5f0, 0.0f0, 0.0f0, 1.0f0,
            next_x, next_y, 0.0f0,
            cos(next_angle) * 0.5f0 + 0.5f0, sin(next_angle) * 0.5f0 + 0.5f0, 0.0f0, 0.0f0, 1.0f0
        ])
    end

    state::ContextState = get_state()
    update_mesh_vertices!(get_immediate_mesh(), vertices)
    color::Vector{Float32} = Float32[state.fill_color...]
    draw_mesh(get_immediate_mesh(), get_context().blank_texture, color)
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

"""
    text(text::String)

Draws a string of text using the loaded font atlas.

# Arguments
- `text`: The string to draw.
"""
function text(text::String)
    ctx::RenderContext = get_context()
    vertices::Vector{GLfloat} = GLfloat[]
    x_cursor::Float32 = 0.0f0

    atlas_cell_w_uv::Float32 = 1.0f0 / ctx.atlas_cols
    atlas_cell_h_uv::Float32 = 1.0f0 / ctx.atlas_rows

    for char::Char in text
        if isascii(char)
            char_code::Int = Int(char) - 32
            col::Int = char_code % ctx.atlas_cols
            row::Int = char_code ÷ ctx.atlas_cols

            u0::Float32 = Float32(col) * atlas_cell_w_uv
            v0::Float32 = 1.0f0 - Float32(row + 1) * atlas_cell_h_uv
            u1::Float32 = u0 + atlas_cell_w_uv
            v1::Float32 = v0 + atlas_cell_h_uv

            char_render_w::Float32 = ctx.char_width
            char_render_h::Float32 = ctx.char_height
            xpos::Float32 = x_cursor
            ypos::Float32 = 0.0f0

            append!(vertices, GLfloat[
                xpos, ypos, 0.0f0,                  u0, v1, 0.0f0, 0.0f0, 1.0f0,
                xpos, ypos + char_render_h, 0.0f0,  u0, v0, 0.0f0, 0.0f0, 1.0f0,
                xpos + char_render_w, ypos + char_render_h, 0.0f0, u1, v0, 0.0f0, 0.0f0, 1.0f0,

                xpos, ypos, 0.0f0,                  u0, v1, 0.0f0, 0.0f0, 1.0f0,
                xpos + char_render_w, ypos + char_render_h, 0.0f0, u1, v0, 0.0f0, 0.0f0, 1.0f0,
                xpos + char_render_w, ypos, 0.0f0,  u1, v1, 0.0f0, 0.0f0, 1.0f0
            ])

            x_cursor += char_render_w
        else
            x_cursor += ctx.char_width
        end
    end

    if !isempty(vertices)
        update_mesh_vertices!(get_immediate_mesh(), vertices)
        color::Vector{Float32} = Float32[get_state().fill_color...]
        draw_mesh(get_immediate_mesh(), ctx.font_texture, color)
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
