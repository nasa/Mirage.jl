# Loading images into OpenGL textures.
"""
    load_texture(filepath::String)::GLuint

Loads an image from the specified filepath and creates an OpenGL texture from it.

# Arguments
- `filepath`: The path to the image file.

# Returns
The ID of the created OpenGL texture.

# Throws
- `error`: If the image cannot be loaded.
"""
function load_texture(filepath::String)::GLuint
    try
        img = FileIO.load(filepath)
        img_rgba = convert(Matrix{RGBA{N0f8}}, img)
        return load_texture(img_rgba)
    catch e
        println("Error loading texture '$filepath': ", e)
        rethrow(e)
    end
end

"""
    load_texture(img_rgba::Matrix{RGBA{N0f8}})::GLuint

Creates an OpenGL texture from a given RGBA image matrix (`RGBA`/`N0f8` from
ColorTypes.jl/FixedPointNumbers.jl, the element type FileIO image loaders produce).

# Arguments
- `img_rgba`: A matrix of `RGBA{N0f8}` representing the image data.

# Returns
The ID of the created OpenGL texture.
"""
function load_texture(img_rgba::Matrix{RGBA{N0f8}})::GLuint
    tex_height, tex_width = size(img_rgba)

    output_img = permutedims(img_rgba[end:-1:1, :], (2, 1))

    output_bytes = vec(reinterpret(UInt8, output_img))

    tex_id = Mirage.gl_gen_texture()
    glBindTexture(GL_TEXTURE_2D, tex_id)
    gl_check_error("binding texture")

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    gl_check_error("setting wrap parameters")

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    gl_check_error("setting filter parameters")

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, tex_width, tex_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, output_bytes)
    glBindTexture(GL_TEXTURE_2D, 0)
    gl_check_error("uploading texture data")

    return tex_id
end

