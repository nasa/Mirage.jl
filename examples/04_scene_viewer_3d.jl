# A compact 3D scene viewer covering meshes, textures, custom shaders, perspective
# cameras, scene-space paths and text, and interactive orbit controls.
#
#   julia --project=examples examples/04_scene_viewer_3d.jl

module SceneViewer3D

using Mirage
using CImGui

const ASSET_DIR = joinpath(@__DIR__, "assets")

const PHONG_VERTEX_SHADER = """
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

    void main() {
        vec4 worldPos = model * vec4(aPos, 1.0);
        FragPos = worldPos.xyz;
        TexCoord = aTexCoord;
        Normal = mat3(transpose(inverse(model))) * aNormal;
        gl_Position = projection * view * worldPos;
    }
"""

const PHONG_FRAGMENT_SHADER = """
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

    void main() {
        vec3 norm = normalize(Normal);
        vec3 lightDir = normalize(lightPos - FragPos);
        vec3 viewDir = normalize(viewPos - FragPos);
        vec3 reflected = reflect(-lightDir, norm);
        float diffuse = max(dot(norm, lightDir), 0.0);
        float specular = 0.45 * pow(max(dot(viewDir, reflected), 0.0), 32.0);
        vec3 lighting = vec3(0.16) + diffuse * lightColor + specular * lightColor;
        vec4 texel = texture(textureSampler, TexCoord) * tintColor;
        FragColor = vec4(texel.rgb * lighting, texel.a);
    }
"""

function initialize_phong_shader()
    shader = Mirage.create_shader_program(PHONG_VERTEX_SHADER, PHONG_FRAGMENT_SHADER)
    for uniform in ("model", "view", "projection", "textureSampler", "lightPos",
                    "viewPos", "lightColor", "tintColor")
        Mirage.initialize_shader_uniform!(shader, uniform)
    end
    return shader
end

function draw_phong(mesh, shader, texture, camera, light, tint)
    Mirage.draw_mesh(mesh, shader, active_shader -> begin
        Mirage.set_uniform(active_shader, "model", Mirage.get_state().transform)
        Mirage.set_uniform(active_shader, "view", Mirage.get_state().view)
        Mirage.set_uniform(active_shader, "projection", Mirage.get_state().projection)
        Mirage.set_uniform(active_shader, "lightPos", light)
        Mirage.set_uniform(active_shader, "viewPos", camera)
        Mirage.set_uniform(active_shader, "lightColor", Float32[1.0, 0.96, 0.86])
        Mirage.set_uniform(active_shader, "tintColor", tint)
        Mirage.glActiveTexture(Mirage.GL_TEXTURE0)
        Mirage.glBindTexture(Mirage.GL_TEXTURE_2D, texture)
        Mirage.set_uniform(active_shader, "textureSampler", 0)
    end)
end

function draw_ground_grid()
    Mirage.beginpath()
    for coordinate in -5:5
        Mirage.moveto(coordinate, -5, -1.5)
        Mirage.lineto(coordinate, 5, -1.5)
        Mirage.moveto(-5, coordinate, -1.5)
        Mirage.lineto(5, coordinate, -1.5)
    end
    Mirage.strokewidth(0.015)
    Mirage.strokecolor(Mirage.rgba(75, 90, 120, 150))
    Mirage.stroke()

    trajectory = [
        (-4.5, -2.6, -1.32),
        (-3.8, -2.35, -1.18),
        (-3.0, -2.12, -0.92),
        (-2.2, -2.0, -0.62),
        (-1.4, -2.08, -0.30),
        (-0.5, -2.22, -0.05),
        (0.4, -2.18, 0.12),
        (1.3, -1.95, 0.28),
        (2.2, -1.55, 0.48),
        (3.0, -1.0, 0.70),
        (3.7, -0.3, 0.90),
    ]

    function trace_trajectory()
        Mirage.beginpath()
        Mirage.moveto(first(trajectory)...)
        for point in Iterators.drop(trajectory, 1)
            Mirage.lineto(point...)
        end
    end

    # A soft outer stroke and crisp center make the path readable against both
    # the grid and textured meshes. Stroke widths are measured in world units.
    trace_trajectory()
    Mirage.strokewidth(0.11)
    Mirage.strokecolor(Mirage.rgba(210, 95, 30, 120))
    Mirage.stroke()

    Mirage.save()
    Mirage.translate(0, 0, 0.012)
    trace_trajectory()
    Mirage.strokewidth(0.045)
    Mirage.strokecolor(Mirage.rgba(255, 205, 80))
    Mirage.stroke()
    Mirage.restore()
end

function pan_camera_target(target, yaw, pitch, distance, mouse_delta, viewport_height)
    cos_pitch = cos(pitch)
    sin_pitch = sin(pitch)
    cos_yaw = cos(yaw)
    sin_yaw = sin(yaw)
    right = (-sin_yaw, cos_yaw, 0.0)
    camera_up = (-sin_pitch * cos_yaw, -sin_pitch * sin_yaw, cos_pitch)
    world_per_pixel = 2 * distance * tan(pi / 8) / max(viewport_height, 1)
    dx, dy = mouse_delta
    return (
        target[1] - dx * world_per_pixel * right[1] + dy * world_per_pixel * camera_up[1],
        target[2] - dx * world_per_pixel * right[2] + dy * world_per_pixel * camera_up[2],
        target[3] - dx * world_per_pixel * right[3] + dy * world_per_pixel * camera_up[3],
    )
end

function main()
    app = MirageApp("Mirage: 3D Scene Viewer"; width = 1200, height = 800)
    cube = nothing
    sphere = nothing
    obj = nothing
    shader = nothing
    texture = UInt32(0)

    yaw = Ref(0.72)
    pitch = Ref(0.42)
    distance = Ref(10.0f0)
    target = Ref((0.0, 0.0, 0.0))
    last_mouse = Ref((0.0, 0.0))
    panning = Ref(false)
    auto_rotate = Ref(true)
    show_grid = Ref(true)
    start_time = time()
    run_started = false

    try
        cube = Mirage.create_cube(2.0)
        sphere = Mirage.create_uv_sphere(1.1, 36, 20)
        obj = Mirage.load_obj_mesh(joinpath(ASSET_DIR, "cube.obj"))
        texture = Mirage.load_texture(joinpath(ASSET_DIR, "testimage.jpg"))
        shader = initialize_phong_shader()

        # The app retains callback objects for their full GLFW lifetime; destroying
        # the app unregisters them with the window.
        set_scroll_callback!(app) do _window, _xoff, yoff
            distance[] = clamp(distance[] - Float32(yoff) * 0.6f0, 4.0f0, 24.0f0)
            request_frame!(app)
        end

        cleanup = function (_app)
            Mirage.glDisable(Mirage.GL_DEPTH_TEST)
            Mirage.glBindTexture(Mirage.GL_TEXTURE_2D, 0)
            texture == 0 || Mirage.destroy_texture!(texture)
            shader === nothing || Mirage.glDeleteProgram(shader.program_id)
            for mesh in (obj, sphere, cube)
                mesh === nothing || Mirage.destroy!(mesh)
            end
            return nothing
        end

        run_started = true
        run!(app; animate = _ -> auto_rotate[], cleanup! = cleanup) do _a
            draw_background_canvas!(app, :scene; projection = :none,
                                    clear_color = (0.025, 0.03, 0.055, 1.0)) do canvas, viewport
                if viewport.clicked
                    last_mouse[] = viewport.mouse_rel
                end
                if viewport.active && !panning[]
                    dx = viewport.mouse_rel[1] - last_mouse[][1]
                    dy = viewport.mouse_rel[2] - last_mouse[][2]
                    yaw[] -= dx * 0.01
                    pitch[] = clamp(pitch[] + dy * 0.01, -1.35, 1.35)
                    last_mouse[] = viewport.mouse_rel
                end

                if viewport.hovered && CImGui.IsMouseClicked(1)
                    panning[] = true
                    last_mouse[] = viewport.mouse_rel
                end
                if panning[] && CImGui.IsMouseDown(1)
                    dx = viewport.mouse_rel[1] - last_mouse[][1]
                    dy = viewport.mouse_rel[2] - last_mouse[][2]
                    target[] = pan_camera_target(
                        target[], yaw[], pitch[], distance[], (dx, dy), canvas.height,
                    )
                    last_mouse[] = viewport.mouse_rel
                elseif panning[]
                    panning[] = false
                end

                r = distance[]
                look_at = target[]
                camera = Float32[
                    look_at[1] + r * cos(pitch[]) * cos(yaw[]),
                    look_at[2] + r * cos(pitch[]) * sin(yaw[]),
                    look_at[3] + r * sin(pitch[]),
                ]
                t = time() - start_time
                animation_t = auto_rotate[] ? t : 0.0
                light = Float32[4.5cos(t * 0.8), 4.5sin(t * 0.8), 4.0]

                Mirage.glEnable(Mirage.GL_DEPTH_TEST)
                Mirage.update_perspective_projection_matrix(
                    canvas.width, canvas.height, 1.0;
                    near = 0.01, far = 100.0, fov = pi / 4,
                )
                Mirage.lookat(camera, Float32[look_at...], Float32[0, 0, 1])

                show_grid[] && draw_ground_grid()

                # Procedural cube, custom Phong lighting, and a loaded texture.
                Mirage.save()
                Mirage.translate(-2.3, 0.2, 0.0)
                Mirage.rotate(animation_t * 0.45, animation_t * 0.65, animation_t * 0.2)
                draw_phong(cube, shader, texture, camera, light,
                           Float32[1.0, 0.78, 0.70, 1.0])
                Mirage.restore()

                # Procedural UV sphere with the same material pipeline.
                Mirage.save()
                Mirage.translate(1.0, -0.3, -0.1)
                Mirage.rotate(0.0, animation_t * 0.7, animation_t * 0.2)
                draw_phong(sphere, shader, texture, camera, light,
                           Float32[0.65, 0.92, 1.0, 1.0])
                Mirage.restore()

                # OBJ loading and the built-in textured mesh shader.
                Mirage.save()
                Mirage.translate(3.2, 1.15, -0.45)
                Mirage.rotate(animation_t * 0.3, 0.3, animation_t * 0.5)
                Mirage.scale(0.8)
                Mirage.draw_mesh(obj, texture, Float32[0.75, 1.0, 0.72, 1.0])
                Mirage.restore()

                Mirage.glBindTexture(Mirage.GL_TEXTURE_2D, 0)

                # A scene-space label shares the same perspective/view matrices.
                Mirage.save()
                Mirage.translate(-4.0, -2.6, 1.35)
                Mirage.rotate(pi / 2, 0, pi)
                Mirage.scale(0.018)
                Mirage.fillcolor(Mirage.rgba(238, 242, 255))
                Mirage.text("Mirage 3D: mesh + texture + Phong")
                Mirage.restore()

                # Make the moving light visible as a small emissive-looking sphere.
                Mirage.save()
                Mirage.translate(light...)
                Mirage.scale(0.18)
                Mirage.draw_mesh(sphere, Float32[1.0, 0.9, 0.42, 1.0])
                Mirage.restore()
            end

            CImGui.SetNextWindowPos(CImGui.ImVec2(20, 20), CImGui.ImGuiCond_FirstUseEver)
            CImGui.SetNextWindowSize(CImGui.ImVec2(360, 150), CImGui.ImGuiCond_FirstUseEver)
            CImGui.Begin("Scene controls")
            CImGui.Text("Left: orbit | Right: pan | Scroll: zoom")
            CImGui.Checkbox("animate objects", auto_rotate)
            CImGui.Checkbox("grid and 3D path", show_grid)
            CImGui.Text("camera distance: $(round(distance[]; digits = 1))")
            CImGui.Text("procedural cube + sphere, OBJ, texture, Phong")
            CImGui.End()
        end
    catch
        # Setup can fail before run! takes ownership of cleanup.
        if !run_started
            try
                texture == 0 || Mirage.destroy_texture!(texture)
                shader === nothing || Mirage.glDeleteProgram(shader.program_id)
                for mesh in (obj, sphere, cube)
                    mesh === nothing || Mirage.destroy!(mesh)
                end
                Mirage.destroy!(app)
            catch
            end
        end
        rethrow()
    end
    return nothing
end

end # module SceneViewer3D

if abspath(PROGRAM_FILE) == @__FILE__
    SceneViewer3D.main()
end
