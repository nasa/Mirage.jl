module MirageTestDemos

using Test
using LinearAlgebra
import Mirage

export Demo, demos, run_all_demos, spinning_square, two_d_primitives, basic_3d_scene,
       lit_textured_3d_scene, canvas_and_texture, api_behavior_tests, test_scene_2d,
       test_scene_3d, gui_canvas_app, gui_3d_app

const REPO_ROOT = normpath(joinpath(@__DIR__, ".."))

struct Demo
    name::Symbol
    title::String
    run::Function
end

function _resource_path(parts...)
    return joinpath(REPO_ROOT, parts...)
end

function _initialize_demo(title::String; width::Int = 800, height::Int = 600)
    @info "Opening Mirage demo window. Close it to continue." title
    return Mirage.MirageApp(title; width, height, docking = false)
end

# Runs a full-window canvas render loop: each frame the demo's `render(canvas)`
# draws into a background canvas that fills the app window. GL resources the demo
# created are torn down via `cleanup!`, which run! invokes before destroying the app
# (i.e. while the OpenGL context is still alive).
function _demo_loop(render::Function, app::Mirage.MirageApp; cleanup!::Function = _ -> nothing)
    Mirage.run!(app; cleanup!) do a
        Mirage.draw_background_canvas!(a, :demo; clear_color = (0, 0, 0, 1)) do canvas, _viewport
            render(canvas)
        end
    end
    return nothing
end

_window_size(canvas::Mirage.Canvas) = (Float32(canvas.width), Float32(canvas.height))

function _label(message::String, x::Number, y::Number; color = Mirage.rgba(230, 235, 245))
    Mirage.save()
    Mirage.translate(x, y)
    Mirage.fillcolor(color)
    Mirage.text(message)
    Mirage.restore()
end

function _checker_texture()
    data = Float32[
        0.10, 0.12, 0.18, 1.0,  0.95, 0.95, 0.80, 1.0,
        0.95, 0.95, 0.80, 1.0,  0.15, 0.36, 0.55, 1.0,
    ]
    texture_id = Mirage.gl_gen_texture()
    Mirage.glBindTexture(Mirage.GL_TEXTURE_2D, texture_id)
    Mirage.glTexParameteri(Mirage.GL_TEXTURE_2D, Mirage.GL_TEXTURE_WRAP_S, Mirage.GL_REPEAT)
    Mirage.glTexParameteri(Mirage.GL_TEXTURE_2D, Mirage.GL_TEXTURE_WRAP_T, Mirage.GL_REPEAT)
    Mirage.glTexParameteri(Mirage.GL_TEXTURE_2D, Mirage.GL_TEXTURE_MIN_FILTER, Mirage.GL_NEAREST)
    Mirage.glTexParameteri(Mirage.GL_TEXTURE_2D, Mirage.GL_TEXTURE_MAG_FILTER, Mirage.GL_NEAREST)
    Mirage.glTexImage2D(
        Mirage.GL_TEXTURE_2D,
        0,
        Mirage.GL_RGBA32F,
        2,
        2,
        0,
        Mirage.GL_RGBA,
        Mirage.GL_FLOAT,
        data,
    )
    Mirage.glBindTexture(Mirage.GL_TEXTURE_2D, 0)
    return texture_id
end

function api_behavior_tests()
    @testset "Mirage CPU-side API" begin
        m = Matrix{Float32}(I, 4, 4)
        Mirage.translate!(m, 2, 3, 4)
        @test m[:, 4] == Float32[2, 3, 4, 1]

        m = Matrix{Float32}(I, 4, 4)
        Mirage.scale!(m, 2, 3, 4)
        @test m[1, 1] == 2
        @test m[2, 2] == 3
        @test m[3, 3] == 4

        m = Matrix{Float32}(I, 4, 4)
        Mirage.rotate!(m, Float32(pi / 2))
        @test m[1, 1] ≈ 0 atol = 1f-6
        @test m[2, 1] ≈ 1 atol = 1f-6

        @test Mirage.rgba(255, 128, 0, 64) ==
              (1.0f0, Float32(128 / 255), 0.0f0, Float32(64 / 255))

        p = Mirage.perspective(Float32(pi / 4), 4.0f0 / 3.0f0, 0.01f0, 100.0f0)
        @test size(p) == (4, 4)
        @test p[4, 3] == -1
    end

    @testset "Mirage GUI API surface" begin
        # These checks are headless-safe: they only assert that the absorbed
        # Dear ImGui + GLFW application layer is present and exported, without
        # creating an OpenGL context or a window.
        @test Mirage.MirageApp isa DataType
        @test Mirage.CanvasViewport isa DataType
        for fn in (:run!, :run_live!, :live_revise!, :begin_frame!, :end_frame!,
                   :request_frame!, :stop!, :get_canvas!, :resize_canvas!,
                   :destroy_canvas!, :draw_canvas!, :draw_background_canvas!,
                   :draw_canvas_image!, :begin_dockspace!, :end_dockspace!,
                   :dock_layout!, :set_scroll_callback!,
                   :set_key_callback!, :set_mouse_button_callback!)
            @test getfield(Mirage, fn) isa Function
            # Every app-layer function is exported — the package's front door.
            @test Base.isexported(Mirage, fn)
        end
        # The drawing API is deliberately NOT exported (used as Mirage.fillrect etc.,
        # mirroring ctx.fillRect) — and must not collide with Base under `using`.
        for fn in (:fill, :resize!, :save, :restore, :fillrect, :translate, :rotate)
            @test !Base.isexported(Mirage, fn)
        end
    end
end

function spinning_square()
    app = _initialize_demo("Mirage Test 1 - README Spinning Square")

    _demo_loop(app) do canvas
        width, height = _window_size(canvas)

        Mirage.save()
        Mirage.translate(width / 2, height / 2)
        Mirage.rotate(time())
        Mirage.fillcolor(Mirage.rgba(255, 40, 40))
        Mirage.rect(-55, -55, 110, 110)
        Mirage.fill()
        Mirage.restore()

        _label("README spinning square", 20, 24)
        _label("Close this window for the next demo", 20, height - 36;
               color = Mirage.rgba(180, 205, 255))
    end

    return nothing
end

function test_scene_2d()
    app = _initialize_demo("Mirage Test 2 - Source 2D Test Scene")

    test_texture_id = UInt32(0)
    try
        test_texture_path = _resource_path("testimage.jpg")
        if isfile(test_texture_path)
            test_texture_id = Mirage.load_texture(test_texture_path)
            @info "Loaded test texture" path = test_texture_path id = test_texture_id
        else
            test_texture_id = _checker_texture()
            @info "Created fallback checkerboard texture" id = test_texture_id
        end

        frame_count = 0
        last_frame_time = time()

        _demo_loop(app; cleanup! = _ -> begin
            test_texture_id == 0 || Mirage.destroy_texture!(test_texture_id)
        end) do canvas
            frame_count += 1
            current_frame_time = time()
            delta_time = current_frame_time - last_frame_time
            last_frame_time = current_frame_time

            Mirage.save()
            Mirage.fillcolor(Mirage.rgba(255, 0, 0, 255))
            Mirage.fillrect(50.0f0, 50.0f0, 100.0f0, 80.0f0)
            Mirage.restore()

            Mirage.save()
            Mirage.fillcolor(Mirage.rgba(0, 255, 0, 255))
            Mirage.fillrect(200.0f0, 100.0f0, 50.0f0, 150.0f0)
            Mirage.restore()

            Mirage.save()
            Mirage.translate(frame_count, frame_count)
            Mirage.scale(sin(frame_count * 0.05) * 0.25 + 0.75)
            Mirage.fillcolor(Mirage.rgba(255, 255, 255, 100))
            Mirage.circle(100)
            Mirage.fill()
            Mirage.restore()

            if test_texture_id != 0
                Mirage.drawimage(50.0f0, 200.0f0, 150.0f0, 150.0f0, Mirage.get_context().font_texture)

                Mirage.save()
                Mirage.translate(250.0f0, 250.0f0)
                Mirage.scale(10)
                Mirage.drawimage(0, 0, 100.0f0, 100.0f0, test_texture_id)
                Mirage.restore()
            end

            fps = round(Int, 1.0 / (delta_time + 1e-9))

            Mirage.save()
            Mirage.translate(50, 400)
            Mirage.scale(2)
            Mirage.fillcolor(Mirage.rgba(255, 255, 0, 200))
            Mirage.text("Hello Julia OpenGL!")
            Mirage.restore()

            Mirage.save()
            Mirage.translate(10, 10)
            Mirage.text("FPS: $fps")
            Mirage.restore()

            Mirage.save()
            Mirage.translate(50, 450)
            Mirage.scale(2)
            Mirage.fillcolor(Mirage.rgba(20, 200, 255, 255))
            Mirage.text("0123456789 ASCII /?!")
            Mirage.restore()

            Mirage.save()
            Mirage.moveto(100, 100)
            Mirage.lineto(200, 200)
            Mirage.lineto(300, 200)
            Mirage.lineto(350, 500)
            Mirage.moveto(500, 200)
            Mirage.lineto(500, 300)
            Mirage.strokewidth(14)
            Mirage.strokecolor(Mirage.rgba(64, 128, 255, 255))
            Mirage.stroke()
            Mirage.restore()

            Mirage.save()
            Mirage.strokewidth(14)
            Mirage.strokecolor(Mirage.rgba(64, 128, 255, 255))
            Mirage.translate(200, 100)
            Mirage.circle(100)
            Mirage.stroke()
            Mirage.restore()

            Mirage.save()
            Mirage.beginpath()
            Mirage.strokewidth(5)
            Mirage.strokecolor(Mirage.rgba(255, 255, 0, 255))
            Mirage.moveto(400, 400)
            Mirage.lineto(500, 400)
            Mirage.lineto(500, 500)
            Mirage.lineto(400, 500)
            Mirage.closepath()
            Mirage.fillcolor(Mirage.rgba(0, 0, 255, 100))
            Mirage.fill()
            Mirage.stroke()
            Mirage.restore()
        end
    catch
        # Resource setup failed before the loop ran; tear the window down ourselves.
        Mirage.destroy!(app)
        rethrow()
    end

    return nothing
end

two_d_primitives() = test_scene_2d()

function canvas_and_texture()
    app = _initialize_demo("Mirage Test 3 - Textures and Canvas")

    canvas = Mirage.create_canvas(192, 192)
    texture_id = UInt32(0)
    test_image = _resource_path("testimage.jpg")

    try
        texture_id = isfile(test_image) ? Mirage.load_texture(test_image) : _checker_texture()

        Mirage.set_canvas(canvas)
        Mirage.clear()
        Mirage.update_ortho_projection_matrix(canvas.width, canvas.height, 1.0)
        Mirage.fillcolor(Mirage.rgba(20, 28, 42))
        Mirage.fillrect(0, 0, canvas.width, canvas.height)
        Mirage.save()
        Mirage.translate(24, 72)
        Mirage.scale(3)
        Mirage.fillcolor(Mirage.rgba(255, 255, 255))
        Mirage.text("Canvas")
        Mirage.restore()
        Mirage.set_canvas()

        start_time = time()
        _demo_loop(app; cleanup! = _ -> begin
            texture_id == 0 || Mirage.destroy_texture!(texture_id)
            Mirage.destroy!(canvas)
        end) do demo_canvas
            width, height = _window_size(demo_canvas)
            t = time() - start_time
            size = min(width, height) * 0.34

            Mirage.save()
            Mirage.translate(width * 0.24, height * 0.28)
            Mirage.scale(1.0 + 0.08sin(2t))
            Mirage.fillcolor(Mirage.rgba(255, 255, 255))
            Mirage.drawimage(-size / 2, -size / 2, size, size, texture_id)
            Mirage.restore()

            Mirage.save()
            Mirage.translate(width * 0.68, height * 0.52)
            Mirage.rotate(t * 0.7)
            Mirage.fillcolor(Mirage.rgba(255, 255, 255))
            Mirage.drawimage(-size / 2, -size / 2, size, size, canvas.texture)
            Mirage.restore()

            _label("Loaded image or generated checker texture", 26, 28)
            _label("Offscreen canvas rendered back into the window", 26, height - 36;
                   color = Mirage.rgba(200, 220, 255))
        end
    catch
        Mirage.destroy!(app)
        rethrow()
    end

    return nothing
end

function test_scene_3d()
    app = _initialize_demo("Mirage Test 4 - Source 3D Test Scene")

    frame_count = 0
    canvas = nothing
    cube_mesh = nothing
    sphere_mesh = nothing
    obj_mesh = nothing
    cube_mesh_for_phong = nothing
    phong_shader = nothing

    try
        canvas = Mirage.create_canvas(24, 24)
        cube_mesh = Mirage.create_cube(10.0f0)
        sphere_mesh = Mirage.create_uv_sphere(4.0f0)
        obj_mesh = Mirage.load_obj_mesh(_resource_path("cube.obj"))

        s = 10.0f0 / 2
        cube_vertices_with_normals = Float32[
            -s, -s, -s,  0,  0, -1,
             s, -s, -s,  0,  0, -1,
             s,  s, -s,  0,  0, -1,
             s,  s, -s,  0,  0, -1,
            -s,  s, -s,  0,  0, -1,
            -s, -s, -s,  0,  0, -1,

            -s, -s,  s,  0,  0,  1,
             s, -s,  s,  0,  0,  1,
             s,  s,  s,  0,  0,  1,
             s,  s,  s,  0,  0,  1,
            -s,  s,  s,  0,  0,  1,
            -s, -s,  s,  0,  0,  1,

            -s,  s,  s, -1,  0,  0,
            -s,  s, -s, -1,  0,  0,
            -s, -s, -s, -1,  0,  0,
            -s, -s, -s, -1,  0,  0,
            -s, -s,  s, -1,  0,  0,
            -s,  s,  s, -1,  0,  0,

             s,  s,  s,  1,  0,  0,
             s,  s, -s,  1,  0,  0,
             s, -s, -s,  1,  0,  0,
             s, -s, -s,  1,  0,  0,
             s, -s,  s,  1,  0,  0,
             s,  s,  s,  1,  0,  0,

            -s, -s, -s,  0, -1,  0,
             s, -s, -s,  0, -1,  0,
             s, -s,  s,  0, -1,  0,
             s, -s,  s,  0, -1,  0,
            -s, -s,  s,  0, -1,  0,
            -s, -s, -s,  0, -1,  0,

            -s,  s, -s,  0,  1,  0,
             s,  s, -s,  0,  1,  0,
             s,  s,  s,  0,  1,  0,
             s,  s,  s,  0,  1,  0,
            -s,  s,  s,  0,  1,  0,
            -s,  s, -s,  0,  1,  0,
        ]
        phong_cube_attributes = [
            Mirage.VertexAttribute(0, 3, Mirage.GL_FLOAT, false, 0),
            Mirage.VertexAttribute(1, 3, Mirage.GL_FLOAT, false, 3 * sizeof(Float32)),
        ]
        cube_mesh_for_phong = Mirage.create_mesh(cube_vertices_with_normals, phong_cube_attributes)

        phong_vertex_shader_source = """
            #version 330 core
            layout (location = 0) in vec3 aPos;
            layout (location = 1) in vec3 aNormal;

            out vec3 FragPos;
            out vec3 Normal;

            uniform mat4 model;
            uniform mat4 view;
            uniform mat4 projection;

            void main()
            {
                FragPos = vec3(model * vec4(aPos, 1.0));
                Normal = mat3(transpose(inverse(model))) * aNormal;
                gl_Position = projection * view * vec4(FragPos, 1.0);
            }
        """

        phong_fragment_shader_source = """
            #version 330 core
            out vec4 FragColor;

            in vec3 FragPos;
            in vec3 Normal;

            uniform vec3 lightPos;
            uniform vec3 viewPos;
            uniform vec3 objectColor;
            uniform vec3 lightColor;

            void main()
            {
                float ambientStrength = 0.1;
                vec3 ambient = ambientStrength * lightColor;

                vec3 norm = normalize(Normal);
                vec3 lightDir = normalize(lightPos - FragPos);
                float diff = max(dot(norm, lightDir), 0.0);
                vec3 diffuse = diff * lightColor;

                float specularStrength = 0.5;
                vec3 viewDir = normalize(viewPos - FragPos);
                vec3 reflectDir = reflect(-lightDir, norm);
                float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
                vec3 specular = specularStrength * spec * lightColor;

                vec3 result = (ambient + diffuse + specular) * objectColor;
                FragColor = vec4(result, 1.0);
            }
        """
        phong_shader = Mirage.create_shader_program(phong_vertex_shader_source, phong_fragment_shader_source)
        for uniform in ("model", "view", "projection", "lightPos", "viewPos",
                        "objectColor", "lightColor")
            Mirage.initialize_shader_uniform!(phong_shader, uniform)
        end

        Mirage.set_canvas(canvas)
        Mirage.clear()
        Mirage.update_ortho_projection_matrix(canvas.width, canvas.height, 1.0)
        Mirage.save()
        Mirage.fillcolor(Mirage.rgba(0, 0, 50, 255))
        Mirage.fillrect(0, 0, canvas.width, canvas.height)
        Mirage.translate(4, 4)
        Mirage.fillcolor(Mirage.rgba(255, 255, 255, 255))
        Mirage.text(":)")
        Mirage.restore()
        Mirage.set_canvas()

        Mirage.glEnable(Mirage.GL_DEPTH_TEST)

        _demo_loop(app; cleanup! = _ -> begin
            Mirage.glDisable(Mirage.GL_DEPTH_TEST)
            phong_shader === nothing || Mirage.glDeleteProgram(phong_shader.program_id)
            for resource in (cube_mesh_for_phong, obj_mesh, sphere_mesh, cube_mesh)
                resource === nothing || Mirage.destroy!(resource)
            end
            canvas === nothing || Mirage.destroy!(canvas)
        end) do demo_canvas
            frame_count += 1
            Mirage.save()
            Mirage.update_perspective_projection_matrix(demo_canvas.width, demo_canvas.height, 1.0)

            Mirage.fillcolor(Mirage.rgba(255, 255, 255, 255))
            Mirage.fillrect(0, 0, 1, 1)

            cam_pos = Float32[cos(frame_count / 100) * 30, sin(frame_count / 100) * 30, 0]
            Mirage.lookat(cam_pos, Float32[0, 0, 0], Float32[0, 0, 1])

            Mirage.save()
            Mirage.translate(0, 0, 10)
            Mirage.scale(0.5)

            Mirage.draw_mesh(cube_mesh_for_phong, phong_shader, shader -> begin
                Mirage.set_uniform(shader, "model", Mirage.get_state().transform)
                Mirage.set_uniform(shader, "view", Mirage.get_state().view)
                Mirage.set_uniform(shader, "projection", Mirage.get_state().projection)
                Mirage.set_uniform(shader, "lightPos", Float32[30, 30, 30])
                Mirage.set_uniform(shader, "viewPos", cam_pos)
                Mirage.set_uniform(shader, "objectColor", Float32[1.0, 0.5, 0.31])
                Mirage.set_uniform(shader, "lightColor", Float32[1.0, 1.0, 1.0])
            end)

            Mirage.save()
            Mirage.strokecolor(Mirage.rgba(255, 0, 0, 255))
            Mirage.beginpath()
            Mirage.circle(20)
            Mirage.stroke()
            Mirage.restore()

            Mirage.restore()

            Mirage.save()
            Mirage.beginpath()
            Mirage.fillcolor(Mirage.rgba(0, 20, 200, 255))
            Mirage.moveto(0, 0, 0)
            Mirage.lineto(10, 0, 0)
            Mirage.lineto(50, 10, 10)
            Mirage.closepath()
            Mirage.fill()
            Mirage.restore()

            Mirage.save()
            Mirage.translate(10, 0, 0)
            Mirage.rotate(pi / 2)
            Mirage.scale(0.5)
            Mirage.draw_mesh(obj_mesh, canvas.texture)
            Mirage.restore()

            Mirage.rotate(frame_count / 30.6, frame_count / 20, frame_count / 40)
            Mirage.draw_mesh(sphere_mesh, canvas.texture)

            Mirage.restore()
        end
    catch
        Mirage.destroy!(app)
        rethrow()
    end

    return nothing
end

basic_3d_scene() = test_scene_3d()

function lit_textured_3d_scene()
    app = _initialize_demo("Mirage Test 5 - Lit Textured 3D and In-Scene 2D")

    cube = Mirage.create_cube(2.0)
    sphere = Mirage.create_uv_sphere(0.85, 32, 16)
    texture_id = UInt32(0)

    vertex_shader = """
        #version 330 core
        layout (location = 0) in vec3 aPos;
        layout (location = 1) in vec2 aTexCoord;
        layout (location = 2) in vec3 aNormal;

        out vec3 FragPos;
        out vec2 TexCoord;
        out vec3 Normal;

        uniform mat4 model;
        uniform mat4 view;
        uniform mat4 projection;

        void main()
        {
            vec4 worldPos = model * vec4(aPos, 1.0);
            FragPos = worldPos.xyz;
            TexCoord = aTexCoord;
            Normal = mat3(transpose(inverse(model))) * aNormal;
            gl_Position = projection * view * worldPos;
        }
    """

    fragment_shader = """
        #version 330 core
        in vec3 FragPos;
        in vec2 TexCoord;
        in vec3 Normal;

        out vec4 FragColor;

        uniform sampler2D textureSampler;
        uniform vec3 lightPos;
        uniform vec3 viewPos;
        uniform vec3 lightColor;
        uniform vec4 tintColor;

        void main()
        {
            vec3 norm = normalize(Normal);
            vec3 lightDir = normalize(lightPos - FragPos);
            vec3 viewDir = normalize(viewPos - FragPos);
            vec3 reflectDir = reflect(-lightDir, norm);

            float diffuseStrength = max(dot(norm, lightDir), 0.0);
            float specularStrength = pow(max(dot(viewDir, reflectDir), 0.0), 32.0) * 0.45;

            vec3 lighting = (0.18 + diffuseStrength) * lightColor + specularStrength * lightColor;
            vec4 texel = texture(textureSampler, TexCoord) * tintColor;
            FragColor = vec4(texel.rgb * lighting, texel.a);
        }
    """

    shader = Mirage.create_shader_program(vertex_shader, fragment_shader)
    for uniform in ("model", "view", "projection", "textureSampler", "lightPos",
                    "viewPos", "lightColor", "tintColor")
        Mirage.initialize_shader_uniform!(shader, uniform)
    end

    try
        texture_path = _resource_path("testimage.jpg")
        texture_id = isfile(texture_path) ? Mirage.load_texture(texture_path) : _checker_texture()
        Mirage.glEnable(Mirage.GL_DEPTH_TEST)

        start_time = time()
        _demo_loop(app; cleanup! = _ -> begin
            Mirage.glDisable(Mirage.GL_DEPTH_TEST)
            texture_id == 0 || Mirage.destroy_texture!(texture_id)
            Mirage.glDeleteProgram(shader.program_id)
            Mirage.destroy!(sphere)
            Mirage.destroy!(cube)
        end) do canvas
            width, height = _window_size(canvas)
            t = time() - start_time
            camera = Float32[5cos(t * 0.25), 6sin(t * 0.25), 3.2]
            light = Float32[3.5cos(t), 3.5sin(t), 4.0]

            Mirage.glEnable(Mirage.GL_DEPTH_TEST)
            Mirage.update_perspective_projection_matrix(canvas.width, canvas.height, 1.0;
                                                        near = 0.01, far = 100.0, fov = pi / 4)
            Mirage.lookat(camera, Float32[0, 0, 0], Float32[0, 0, 1])

            Mirage.save()
            Mirage.translate(-1.35, 0, 0)
            Mirage.rotate(t * 0.45, t * 0.55, t * 0.2)
            Mirage.draw_mesh(cube, shader, s -> begin
                Mirage.set_uniform(s, "model", Mirage.get_state().transform)
                Mirage.set_uniform(s, "view", Mirage.get_state().view)
                Mirage.set_uniform(s, "projection", Mirage.get_state().projection)
                Mirage.set_uniform(s, "lightPos", light)
                Mirage.set_uniform(s, "viewPos", camera)
                Mirage.set_uniform(s, "lightColor", Float32[1.0, 0.96, 0.86])
                Mirage.set_uniform(s, "tintColor", Float32[1.0, 0.82, 0.72, 1.0])
                Mirage.glActiveTexture(Mirage.GL_TEXTURE0)
                Mirage.glBindTexture(Mirage.GL_TEXTURE_2D, texture_id)
                Mirage.set_uniform(s, "textureSampler", 0)
            end)
            Mirage.restore()

            Mirage.save()
            Mirage.translate(1.85, -1.15, 0.35)
            Mirage.rotate(t * 0.2, t * 0.8, t * 0.35)
            Mirage.draw_mesh(sphere, shader, s -> begin
                Mirage.set_uniform(s, "model", Mirage.get_state().transform)
                Mirage.set_uniform(s, "view", Mirage.get_state().view)
                Mirage.set_uniform(s, "projection", Mirage.get_state().projection)
                Mirage.set_uniform(s, "lightPos", light)
                Mirage.set_uniform(s, "viewPos", camera)
                Mirage.set_uniform(s, "lightColor", Float32[1.0, 0.98, 0.9])
                Mirage.set_uniform(s, "tintColor", Float32[0.72, 1.0, 0.78, 1.0])
                Mirage.glActiveTexture(Mirage.GL_TEXTURE0)
                Mirage.glBindTexture(Mirage.GL_TEXTURE_2D, texture_id)
                Mirage.set_uniform(s, "textureSampler", 0)
            end)
            Mirage.restore()

            Mirage.glBindTexture(Mirage.GL_TEXTURE_2D, 0)

            Mirage.save()
            Mirage.translate(-2.65, -2.1, 1.32)
            Mirage.rotate(pi / 2, 0, 0)
            Mirage.scale(0.018)
            Mirage.beginpath()
            Mirage.moveto(0, 0)
            Mirage.lineto(88, -36)
            Mirage.lineto(168, -4)
            Mirage.lineto(238, -44)
            Mirage.strokecolor(Mirage.rgba(255, 210, 95, 255))
            Mirage.strokewidth(5)
            Mirage.stroke()
            Mirage.restore()

            Mirage.save()
            Mirage.translate(-2.7, -2.12, 1.7)
            Mirage.rotate(pi / 2, 0, pi)
            Mirage.scale(0.016)
            Mirage.fillcolor(Mirage.rgba(245, 248, 255))
            Mirage.text("Phong lighting + texture")
            Mirage.restore()
        end
    catch
        Mirage.destroy!(app)
        rethrow()
    end

    return nothing
end

# --- MirageApp (Dear ImGui) GUI demos ---------------------------------------
# These exercise the absorbed application layer: a windowed app with ImGui panels
# and Mirage canvases rendered into ImGui windows. Close the window to advance.

function gui_canvas_app()
    app = Mirage.MirageApp("Mirage GUI Demo - 2D Canvas in ImGui"; width = 960, height = 640)
    speed = Ref(1.0f0)
    Mirage.run!(app) do a
        Mirage.draw_background_canvas!(a, :main) do canvas, viewport
            # draw_canvas! applies a pixel-space ortho projection by default
            Mirage.save()
            Mirage.translate(canvas.width / 2, canvas.height / 2)
            Mirage.rotate(time() * speed[])
            Mirage.fillcolor(Mirage.rgba(80, 160, 255))
            Mirage.rect(-60, -60, 120, 120)
            Mirage.fill()
            Mirage.restore()
        end

        Mirage.CImGui.SetNextWindowPos(Mirage.CImGui.ImVec2(20, 20), Mirage.CImGui.ImGuiCond_FirstUseEver)
        Mirage.CImGui.Begin("Controls")
        Mirage.CImGui.Text("Close this window to advance to the next demo.")
        Mirage.CImGui.SliderFloat("spin speed", speed, 0.0f0, 5.0f0)
        Mirage.CImGui.End()
    end
    return nothing
end

function gui_3d_app()
    app = Mirage.MirageApp("Mirage GUI Demo - 3D in ImGui"; width = 960, height = 680)
    mesh = Mirage.create_cube(1.0)
    Mirage.run!(app) do a
        Mirage.draw_background_canvas!(a, :scene; clear_color = (0.05, 0.05, 0.08, 1.0),
                                       projection = :none) do canvas, viewport
            Mirage.glEnable(Mirage.GL_DEPTH_TEST)
            Mirage.update_perspective_projection_matrix(
                canvas.width, canvas.height, 1.0; near = 0.01, far = 100.0, fov = pi / 4)
            Mirage.lookat(Float32[4, 4, 3], Float32[0, 0, 0], Float32[0, 0, 1])
            Mirage.save()
            Mirage.rotate(time() * 0.5, time() * 0.3, 0.0)
            Mirage.draw_mesh(mesh, Float32[0.4, 0.7, 1.0, 1.0])
            Mirage.restore()
        end

        Mirage.CImGui.SetNextWindowPos(Mirage.CImGui.ImVec2(20, 20), Mirage.CImGui.ImGuiCond_FirstUseEver)
        Mirage.CImGui.Begin("Info")
        Mirage.CImGui.Text("An auto-rotating cube rendered by Mirage.")
        Mirage.CImGui.Text("Close this window to finish the demos.")
        Mirage.CImGui.End()
    end
    return nothing
end

function demos()
    return Demo[
        Demo(:spinning_square, "README spinning square", spinning_square),
        Demo(:two_d_primitives, "2D primitives, paths, and text", two_d_primitives),
        Demo(:canvas_and_texture, "Textures and offscreen canvas", canvas_and_texture),
        Demo(:basic_3d_scene, "Basic 3D scene", basic_3d_scene),
        Demo(:lit_textured_3d_scene, "Lit textured 3D scene with in-scene 2D", lit_textured_3d_scene),
        Demo(:gui_canvas_app, "GUI: 2D canvas inside a Dear ImGui window", gui_canvas_app),
        Demo(:gui_3d_app, "GUI: 3D scene inside a Dear ImGui window", gui_3d_app),
    ]
end

function run_all_demos(selected::Vector{Symbol} = Symbol[])
    wanted = isempty(selected) ? demos() : filter(demo -> demo.name in selected, demos())
    missing = setdiff(selected, getfield.(demos(), :name))
    isempty(missing) || error("Unknown Mirage demo(s): $(join(string.(missing), ", "))")

    for demo in wanted
        @testset "$(demo.title)" begin
            @test isnothing(demo.run())
        end
    end

    return nothing
end

end # module MirageTestDemos
