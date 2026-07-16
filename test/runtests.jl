using Test
using Mirage

const _hook_before_revise = Mirage._live_revise_hook[]
using Revise

const EXAMPLES_DIR = normpath(joinpath(@__DIR__, "..", "examples"))
const EXAMPLES = [
    (name = :minimal_app, file = "01_minimal_app.jl", module_name = :MinimalApp),
    (name = :live_reload, file = "02_live_reload.jl", module_name = :LiveReload),
    (name = :orbital_dynamics, file = "03_orbital_dynamics.jl", module_name = :OrbitalDynamics),
    (name = :scene_viewer_3d, file = "04_scene_viewer_3d.jl", module_name = :SceneViewer3D),
    (name = :rendering_gallery_2d, file = "05_rendering_gallery_2d.jl", module_name = :RenderingGallery2D),
]

for example in EXAMPLES
    include(joinpath(EXAMPLES_DIR, example.file))
end

function _env_flag(name)
    return lowercase(strip(get(ENV, name, "0"))) in ("1", "true", "yes", "on")
end

function _selected_examples()
    value = strip(get(ENV, "MIRAGE_TEST_EXAMPLES", ""))
    return isempty(value) ? Symbol[] : Symbol.(strip.(split(value, ",")))
end

function run_interactive_examples(selected = Symbol[])
    known = getfield.(EXAMPLES, :name)
    missing = setdiff(selected, known)
    isempty(missing) || error("Unknown example(s): $(join(missing, ", "))")
    wanted = isempty(selected) ? EXAMPLES : filter(example -> example.name in selected, EXAMPLES)
    for example in wanted
        @info "Opening example; close its window to continue." name = example.name
        @test isnothing(getfield(Main, example.module_name).main())
    end
end

@testset "Mirage" begin
    @test _hook_before_revise === nothing
    @test Mirage._live_revise_hook[] !== nothing

    for example in EXAMPLES
        @test getfield(getfield(Main, example.module_name), :main) isa Function
    end

    @testset "Orbital example" begin
        O = Main.OrbitalDynamics

        body = O.Body("Drifter", 1.0, 5.0, (1f0, 1f0, 1f0, 1f0),
                      (1.0, 2.0), (0.5, 1.5))
        state = O.SimulationState([body], [[body.position]], 0.0, 0.5)
        O.verlet_step!(state, 0.5)
        @test collect(state.bodies[1].position) ≈ [1.5, 2.5]

        state = O.reset_state()
        separations = Float64[]
        for step in 1:5_000
            O.verlet_step!(state, 0.001)
            step % 20 == 0 && push!(separations,
                O.vnorm(O.vsub(state.bodies[3].position, state.bodies[2].position)))
        end
        @test all(x -> 0.2 < x < 0.4, extrema(separations))

        center = (1.25, -0.75)
        world = (4.0, 2.5)
        screen = O.world_to_screen(world, 800, 600, 50.0, center)
        @test collect(O.screen_to_world(screen, 800, 600, 50.0, center)) ≈ collect(world)
    end

    if _env_flag("MIRAGE_TEST_INTERACTIVE")
        run_interactive_examples(_selected_examples())
    end
end
