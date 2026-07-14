# 4x4 matrix transform builders (translation, rotation, scaling).

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
    translation = T[
        1.0 0.0 0.0 tx;
        0.0 1.0 0.0 ty;
        0.0 0.0 1.0 tz;
        0.0 0.0 0.0 1.0
    ]
    result = matrix * translation
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
    c = cos(angle)
    s = sin(angle)
    rotation = T[
        c   -s    0.0  0.0;
        s    c    0.0  0.0;
        0.0  0.0  1.0  0.0;
        0.0  0.0  0.0  1.0
    ]
    result = matrix * rotation
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
    # Validate axis input
    length(axis) == 3 || throw(ArgumentError("Axis must be 3-element vector"))
    
    # Manual normalization
    norm = sqrt(sum(x -> x^2, axis))
    norm ≈ 0 && throw(ArgumentError("Rotation axis cannot be zero vector"))
    axis_normalized = axis ./ norm

    # Rotation matrix components
    c = cos(angle)
    s = sin(angle)
    t = 1 - c
    x, y, z = axis_normalized

    # Construct rotation matrix
    rotation = T[
        t*x^2 + c      t*x*y - s*z   t*x*z + s*y   0.0;
        t*x*y + s*z    t*y^2 + c     t*y*z - s*x   0.0;
        t*x*z - s*y    t*y*z + s*x   t*z^2 + c     0.0;
        0.0            0.0           0.0           1.0
    ]

    # In-place matrix update
    result = matrix * rotation
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
    scaling = T[
        sx  0.0  0.0  0.0;
        0.0  sy   0.0  0.0;
        0.0  0.0  sz   0.0;
        0.0  0.0  0.0  1.0
    ]
    result = matrix * scaling
    for i in 1:size(matrix, 1), j in 1:size(matrix, 2)
        matrix[i, j] = result[i, j]
    end
    return matrix
end

