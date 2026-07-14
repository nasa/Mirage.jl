# Projection and camera matrices (ortho/perspective/view) and vector-math helpers.
# Orthographic projection matrix
# Maps x=[left, right] to [-1, 1] and y=[top, bottom] to [1, -1] (OpenGL coords)
"""
    ortho(left::Float32, right::Float32, bottom::Float32, top::Float32, zNear::Float32 = -1.0f0, zFar::Float32 = 1.0f0)::Matrix{Float32}

Creates an orthographic projection matrix.

# Arguments
- `left`: The x-coordinate of the left vertical clipping plane.
- `right`: The x-coordinate of the right vertical clipping plane.
- `bottom`: The y-coordinate of the bottom horizontal clipping plane.
- `top`: The y-coordinate of the top horizontal clipping plane.
- `zNear`: The distance to the near clipping plane (defaults to -1.0f0).
- `zFar`: The distance to the far clipping plane (defaults to 1.0f0).

# Returns
A 4x4 orthographic projection matrix.
"""
function ortho(left::Float32, right::Float32, bottom::Float32, top::Float32, zNear::Float32 = -1.0f0, zFar::Float32 = 1.0f0)::Matrix{Float32}
    mat = zeros(Float32, 4, 4)
    mat[1, 1] = 2.0f0 / (right - left)
    mat[2, 2] = 2.0f0 / (top - bottom) # Flipped y-axis mapping
    mat[3, 3] = -2.0f0 / (zFar - zNear)
    mat[1, 4] = -(right + left) / (right - left)
    mat[2, 4] = -(top + bottom) / (top - bottom) # Flipped y-axis mapping
    mat[3, 4] = -(zFar + zNear) / (zFar - zNear)
    mat[4, 4] = 1.0f0
    return mat
end

"""
    perspective(fov::Float32, aspectRatio::Float32, near::Float32, far::Float32)::Matrix{Float32}

Creates a perspective projection matrix.

# Arguments
- `fov`: The field of view in radians.
- `aspectRatio`: The aspect ratio of the viewport (width / height).
- `near`: The distance to the near clipping plane.
- `far`: The distance to the far clipping plane.

# Returns
A 4x4 perspective projection matrix.
"""
function perspective(fov::Float32, aspectRatio::Float32, near::Float32, far::Float32)::Matrix{Float32}
    top = near * tan(fov/2)
    bottom = -1*top
    right = top * aspectRatio
    left = -1*right

    return Float32[
        2*near/(right-left) 0                   (right+left)/(right-left) 0;
        0                   2*near/(top-bottom) (top+bottom)/(top-bottom) 0;
        0                   0                   -1*(far+near)/(far-near) -2*far*near/(far-near);
        0                   0                   -1                        0
    ]
end

"""
    view(position, target, up = [0, 0, 1])

Creates a view matrix (camera matrix) that transforms world coordinates to view coordinates.

# Arguments
- `position`: The position of the camera in world space.
- `target`: The point in world space that the camera is looking at.
- `up`: The up direction of the camera (defaults to `[0, 0, 1]`).

# Returns
A 4x4 view matrix.
"""
function view(position, target, up = [0, 0, 1])
  z = normalize(position - target)
  x = normalize(cross(up, z))
  y = cross(z, x)

  return Float32[
      x[1] x[2] x[3] -dot(x, position);
      y[1] y[2] y[3] -dot(y, position);
      z[1] z[2] z[3] -dot(z, position);
      0    0    0    1
  ]
end

"""
    normalize(v::Vector{Float32})::Vector{Float32}

Normalizes a 3-element Float32 vector.

# Arguments
- `v`: The input vector.

# Returns
The normalized vector.
"""
function normalize(v::Vector{T})::Vector{T} where T
    len::Number = sqrt(sum(v .^ 2))
    return len > 0 ? v ./ len : v
end

"""
    cross(a::Vector{Float32}, b::Vector{Float32})::Vector{Float32}

Computes the cross product of two 3-element Float32 vectors.

# Arguments
- `a`: The first vector.
- `b`: The second vector.

# Returns
The cross product vector.
"""
function cross(a::Vector{Float32}, b::Vector{Float32})::Vector{Float32}
    return Float32[
        a[2] * b[3] - a[3] * b[2],
        a[3] * b[1] - a[1] * b[3],
        a[1] * b[2] - a[2] * b[1]
    ]
end

"""
    dot(a::Vector{Float32}, b::Vector{Float32})::Float32

Computes the dot product of two 3-element Float32 vectors.

# Arguments
- `a`: The first vector.
- `b`: The second vector.

# Returns
The dot product (a scalar value).
"""
function dot(a::Vector{Float32}, b::Vector{Float32})::Float32
    return sum(a .* b)
end

"""
    update_ortho_projection_matrix(width=get_context().width,
                                   height=get_context().height,
                                   dpi_scaling=get_context().dpi_scaling)

Updates the orthographic projection matrix based on the current context's width, height, and DPI scaling.
Also sets the OpenGL viewport.

# Arguments
- `width`: The width of the viewport (defaults to `get_context().width`).
- `height`: The height of the viewport (defaults to `get_context().height`).
- `dpi_scaling`: The DPI scaling factor (defaults to `get_context().dpi_scaling`).
"""
function update_ortho_projection_matrix(width=get_context().width,
                                        height=get_context().height,
                                        dpi_scaling=get_context().dpi_scaling)
    # Map pixel coords (0, width) -> (-1, 1) and (0, height) -> (1, -1)
    get_state().projection = ortho(0.0f0, Float32(width / dpi_scaling), Float32(height / dpi_scaling), 0.0f0)
    glViewport(0, 0, width, height)
end

"""
    update_perspective_projection_matrix(width=get_context().width,
                                         height=get_context().height,
                                         dpi_scaling=get_context().dpi_scaling;
                                         near = 0.01,
                                         far = 10_000)

Updates the perspective projection matrix based on the current context's width, height, and DPI scaling.
Also sets the OpenGL viewport.

# Arguments
- `width`: The width of the viewport (defaults to `get_context().width`).
- `height`: The height of the viewport (defaults to `get_context().height`).
- `dpi_scaling`: The DPI scaling factor (defaults to `get_context().dpi_scaling`).
- `near`: The distance to the near clipping plane (defaults to 0.01).
- `far`: The distance to the far clipping plane (defaults to 10_000).
- `fov`: The field of view (FOV) of the camera (defaults to pi / 4).
"""
function update_perspective_projection_matrix(width=get_context().width,
                                              height=get_context().height,
                                              dpi_scaling=get_context().dpi_scaling;
                                              near = 0.01,
                                              far = 10_000,
                                              fov = pi / 4)
    get_state().projection = perspective(Float32(fov), Float32(width / height), Float32(near), Float32(far))
    glViewport(0, 0, width, height)
end

