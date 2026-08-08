"""
    translate!(matrix::Matrix{T}, tx::Real, ty::Real, tz::Real = 0.0) where T

Applies a translation to a 4x4 transformation matrix in-place.

# Arguments
- `matrix`: The 4x4 transformation matrix to modify.
- `tx`: The translation amount along the x-axis.
- `ty`: The translation amount along the y-axis.
- `tz`: The translation amount along the z-axis (defaults to 0.0).

# Returns
The modified transformation matrix.
"""
function translate!(matrix::Matrix{T}, tx::Real, ty::Real, tz::Real = 0.0) where T
    translation::Matrix{T} = T[
        1.0 0.0 0.0 tx;
        0.0 1.0 0.0 ty;
        0.0 0.0 1.0 tz;
        0.0 0.0 0.0 1.0
    ]
    result::Matrix{T} = matrix * translation
    for i in 1:size(matrix, 1), j in 1:size(matrix, 2)
        matrix[i, j] = result[i, j]
    end
    return matrix
end

"""
    rotate!(matrix::Matrix{T}, angle::Real) where T

Applies a 2D rotation around the Z-axis to a 4x4 transformation matrix in-place.

# Arguments
- `matrix`: The 4x4 transformation matrix to modify.
- `angle`: The rotation angle in radians.

# Returns
The modified transformation matrix.
"""
function rotate!(matrix::Matrix{T}, angle::Real) where T
    c::Real = cos(angle)
    s::Real = sin(angle)
    rotation::Matrix{T} = T[
        c   -s    0.0  0.0;
        s    c    0.0  0.0;
        0.0  0.0  1.0  0.0;
        0.0  0.0  0.0  1.0
    ]
    result::Matrix{T} = matrix * rotation
    for i in 1:size(matrix, 1), j in 1:size(matrix, 2)
        matrix[i, j] = result[i, j]
    end
    return matrix
end

"""
    rotate!(matrix::Matrix{T}, angle::Real, axis::Vector{T}) where T

Applies a 3D rotation around a specified axis to a 4x4 transformation matrix in-place.

# Arguments
- `matrix`: The 4x4 transformation matrix to modify.
- `angle`: The rotation angle in radians.
- `axis`: A 3-element vector specifying the rotation axis.

# Throws
- `ArgumentError`: If the axis is not a 3-element vector or is a zero vector.

# Returns
The modified transformation matrix.
"""
function rotate!(matrix::Matrix{T}, angle::Real, axis::Vector{T}) where T
    if length(axis) != 3
        throw(ArgumentError("Axis must be 3-element vector"))
    end
    
    norm::Real = sqrt(sum(x -> x^2, axis))
    if norm ≈ 0
        throw(ArgumentError("Rotation axis cannot be zero vector"))
    end
    axis_normalized::Vector{T} = axis ./ norm

    # Rotation matrix components
    c::Real = cos(angle)
    s::Real = sin(angle)
    t::Real = 1 - c
    x::Real, y::Real, z::Real = axis_normalized

    # Construct rotation matrix
    rotation::Matrix{T} = T[
        t*x^2 + c      t*x*y - s*z   t*x*z + s*y   0.0;
        t*x*y + s*z    t*y^2 + c     t*y*z - s*x   0.0;
        t*x*z - s*y    t*y*z + s*x   t*z^2 + c     0.0;
        0.0            0.0           0.0           1.0
    ]

    result::Matrix{T} = matrix * rotation
    for i in 1:size(matrix, 1), j in 1:size(matrix, 2)
        matrix[i, j] = result[i, j]
    end
    return matrix
end

"""
    scale!(matrix::Matrix{T}, sx::Real, sy::Real, sz::Real = 1.0) where T

Applies a scaling transformation to a 4x4 transformation matrix in-place.

# Arguments
- `matrix`: The 4x4 transformation matrix to modify.
- `sx`: The scaling factor along the x-axis.
- `sy`: The scaling factor along the y-axis.
- `sz`: The scaling factor along the z-axis (defaults to 1.0).

# Returns
The modified transformation matrix.
"""
function scale!(matrix::Matrix{T}, sx::Real, sy::Real, sz::Real = 1.0) where T
    scaling::Matrix{T} = T[
        sx  0.0  0.0  0.0;
        0.0  sy   0.0  0.0;
        0.0  0.0  sz   0.0;
        0.0  0.0  0.0  1.0
    ]
    result::Matrix{T} = matrix * scaling
    for i in 1:size(matrix, 1), j in 1:size(matrix, 2)
        matrix[i, j] = result[i, j]
    end
    return matrix
end

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
