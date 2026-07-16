# A normalized four-body gravity sandbox and Dear ImGui scientific dashboard.
# Every body can be selected, dragged, and thrown; pause the simulation to inspect
# the exact force contribution from each neighbor.
#
#   julia --project=examples examples/03_orbital_dynamics.jl

module OrbitalDynamics

using Mirage
using CImGui

const Vec2 = NTuple{2, Float64}
const DEFAULT_DT = 0.002
const DEFAULT_G = 1.0
const DEFAULT_SOFTENING = 0.08

vadd(a::Vec2, b::Vec2)::Vec2 = (a[1] + b[1], a[2] + b[2])
vsub(a::Vec2, b::Vec2)::Vec2 = (a[1] - b[1], a[2] - b[2])
vscale(a::Vec2, s::Real)::Vec2 = (a[1] * s, a[2] * s)
vdot(a::Vec2, b::Vec2) = a[1] * b[1] + a[2] * b[2]
vnorm(a::Vec2) = sqrt(vdot(a, a))

mutable struct Body
    name::String
    mass::Float64
    display_radius::Float64
    color::NTuple{4, Float32}
    position::Vec2
    previous_position::Vec2
end

mutable struct SimulationState
    bodies::Vector{Body}
    trails::Vector{Vector{Vec2}}
    time::Float64
    last_dt::Float64
end

function preset_bodies(dt::Real = DEFAULT_DT)
    # Circular-orbit approximations in illustrative normalized units. The star's
    # small counter-velocity gives the whole preset zero net linear momentum.
    # The blue body is a modest giant planet. Its moon is four orders of
    # magnitude lighter and starts well inside the planet's Hill sphere, so the
    # moon remains visibly bound to the planet instead of following a solar orbit.
    masses = (1000.0, 10.0, 0.001, 2.5)
    moon_separation = 0.3
    positions = ((0.0, 0.0), (5.0, 0.0), (5.0 + moon_separation, 0.0), (11.0, 0.0))
    inner_speed = sqrt(DEFAULT_G * masses[1] / 5.0)
    moon_speed = inner_speed + sqrt(DEFAULT_G * masses[2] / moon_separation)
    outer_speed = sqrt(DEFAULT_G * masses[1] / 11.0)
    moving_v = ((0.0, inner_speed), (0.0, moon_speed), (0.0, outer_speed))
    star_vy = -(masses[2] * moving_v[1][2] + masses[3] * moving_v[2][2] +
                masses[4] * moving_v[3][2]) / masses[1]
    velocities = ((0.0, star_vy), moving_v...)
    names = ("Star", "Inner planet", "Moon", "Outer planet")
    # Screen-space marker sizes stay legible regardless of camera zoom. They are
    # intentionally illustrative rather than proportional to physical radii.
    radii = (16.0, 11.0, 8.0, 13.0)
    colors = (
        (1.00f0, 0.72f0, 0.20f0, 1.0f0),
        (0.25f0, 0.68f0, 1.00f0, 1.0f0),
        (0.82f0, 0.86f0, 0.92f0, 1.0f0),
        (0.94f0, 0.38f0, 0.30f0, 1.0f0),
    )
    return [Body(names[i], masses[i], radii[i], colors[i], positions[i],
                 vsub(positions[i], vscale(velocities[i], dt))) for i in eachindex(names)]
end

function reset_state(dt::Real = DEFAULT_DT)
    bodies = preset_bodies(dt)
    return SimulationState(bodies, [[b.position] for b in bodies], 0.0, Float64(dt))
end

function reset!(state::SimulationState, dt::Real = DEFAULT_DT)
    fresh = reset_state(dt)
    state.bodies = fresh.bodies
    state.trails = fresh.trails
    state.time = fresh.time
    state.last_dt = fresh.last_dt
    return state
end

function body_velocity(state::SimulationState, i::Integer)::Vec2
    return vscale(
        vsub(state.bodies[i].position, state.bodies[i].previous_position),
        inv(state.last_dt)
    )
end

function set_body_velocity!(state::SimulationState, i::Integer, velocity::Vec2)
    body = state.bodies[i]
    body.previous_position = vsub(body.position, vscale(velocity, state.last_dt))
    return body
end

"""Acceleration on `body_index`, split into one vector per other body."""
function acceleration_contributions(bodies::Vector{Body}, body_index::Integer;
                                    G::Real = DEFAULT_G,
                                    softening::Real = DEFAULT_SOFTENING)
    origin = bodies[body_index].position
    contributions = Pair{Int, Vec2}[]
    for j in eachindex(bodies)
        j == body_index && continue
        offset = vsub(bodies[j].position, origin)
        radius2 = vdot(offset, offset) + Float64(softening)^2
        factor = Float64(G) * bodies[j].mass / (radius2 * sqrt(radius2))
        push!(contributions, j => vscale(offset, factor))
    end
    return contributions
end

function total_acceleration(bodies::Vector{Body}, body_index::Integer; kwargs...)
    result = (0.0, 0.0)
    for (_j, contribution) in acceleration_contributions(bodies, body_index; kwargs...)
        result = vadd(result, contribution)
    end
    return result
end

function dominant_influencer(bodies::Vector{Body}, body_index::Integer; kwargs...)
    contributions = acceleration_contributions(bodies, body_index; kwargs...)
    isempty(contributions) && return nothing
    return first(contributions[argmax(map(pair -> vnorm(last(pair)), contributions))])
end

# A fixed-step position-Verlet update. New positions are computed together, so
# body ordering cannot leak into the force calculation. The actively dragged body
# is held while all other bodies keep integrating around its live position.
function verlet_step!(state::SimulationState, dt::Real = state.last_dt;
                      G::Real = DEFAULT_G,
                      softening::Real = DEFAULT_SOFTENING,
                      dragged::Union{Nothing, Int} = nothing)
    h = Float64(dt)
    old_h = state.last_dt
    accelerations = [total_acceleration(state.bodies, i; G, softening)
                     for i in eachindex(state.bodies)]
    next_positions = Vec2[]
    for i in eachindex(state.bodies)
        body = state.bodies[i]
        if i == dragged
            push!(next_positions, body.position)
        else
            velocity_displacement = vscale(vsub(body.position, body.previous_position), h / old_h)
            push!(next_positions,
                  vadd(vadd(body.position, velocity_displacement), vscale(accelerations[i], h^2)))
        end
    end
    for i in eachindex(state.bodies)
        body = state.bodies[i]
        if i == dragged
            body.previous_position = body.position
        else
            body.previous_position = body.position
            body.position = next_positions[i]
        end
    end
    state.time += h
    state.last_dt = h
    return state
end

function total_energy(state::SimulationState; G::Real = DEFAULT_G,
                      softening::Real = DEFAULT_SOFTENING)
    kinetic = sum(0.5 * body.mass * vdot(body_velocity(state, i), body_velocity(state, i))
                  for (i, body) in pairs(state.bodies))
    potential = 0.0
    for i in 1:length(state.bodies)-1, j in i+1:length(state.bodies)
        separation = vnorm(vsub(state.bodies[j].position, state.bodies[i].position))
        potential -= Float64(G) * state.bodies[i].mass * state.bodies[j].mass /
                     sqrt(separation^2 + Float64(softening)^2)
    end
    return kinetic + potential
end

function momentum(state::SimulationState)
    total = (0.0, 0.0)
    for (i, body) in pairs(state.bodies)
        total = vadd(total, vscale(body_velocity(state, i), body.mass))
    end
    return total
end

function advance!(state::SimulationState, frame_dt::Real; substeps::Integer = 4,
                  G::Real = DEFAULT_G,
                  softening::Real = DEFAULT_SOFTENING,
                  dragged::Union{Nothing, Int} = nothing,
                  trail_length::Integer = 240)
    h = Float64(frame_dt) / max(1, Int(substeps))
    for _ in 1:max(1, Int(substeps))
        verlet_step!(state, h; G, softening, dragged)
    end
    for (trail, body) in zip(state.trails, state.bodies)
        push!(trail, body.position)
        while length(trail) > max(1, Int(trail_length))
            popfirst!(trail)
        end
    end
    return state
end

function drag_release_velocity(start_position::Vec2, end_position::Vec2, elapsed::Real;
                               max_speed::Real = 40.0)
    elapsed <= 0 && return (0.0, 0.0)
    raw = vscale(vsub(end_position, start_position), inv(Float64(elapsed)))
    speed = vnorm(raw)
    return speed > max_speed ? vscale(raw, Float64(max_speed) / speed) : raw
end

function world_to_screen(position::Vec2, width::Real, height::Real, scale::Real,
                         camera_center::Vec2 = (0.0, 0.0))
    return (
        width / 2 + (position[1] - camera_center[1]) * scale,
        height / 2 - (position[2] - camera_center[2]) * scale
    )
end

function screen_to_world(position::Tuple{<:Real, <:Real}, width::Real, height::Real, scale::Real,
                         camera_center::Vec2 = (0.0, 0.0))::Vec2
    return (
        camera_center[1] + (position[1] - width / 2) / scale,
        camera_center[2] - (position[2] - height / 2) / scale
    )
end

function zoom_camera_at(camera_center::Vec2, mouse::Tuple{<:Real, <:Real},
                        width::Real, height::Real, old_zoom::Real, new_zoom::Real)::Vec2
    cursor_world = screen_to_world(mouse, width, height, old_zoom, camera_center)
    dx = mouse[1] - width / 2
    dy = mouse[2] - height / 2
    return (cursor_world[1] - dx / new_zoom, cursor_world[2] + dy / new_zoom)
end

function nearest_body(state::SimulationState, mouse, width, height, scale,
                      camera_center::Vec2 = (0.0, 0.0))
    best = nothing
    best_distance = Inf
    for (i, body) in pairs(state.bodies)
        screen = world_to_screen(body.position, width, height, scale, camera_center)
        distance = vnorm((Float64(mouse[1] - screen[1]), Float64(mouse[2] - screen[2])))
        hit_radius = max(body.display_radius + 8, 18.0)
        if distance <= hit_radius && distance < best_distance
            best, best_distance = i, distance
        end
    end
    return best
end

function draw_arrow(origin::Vec2, vector::Vec2; color = Mirage.rgba(120, 230, 180))
    tip = vadd(origin, vector)
    Mirage.beginpath()
    Mirage.moveto(origin...)
    Mirage.lineto(tip...)
    Mirage.strokewidth(2)
    Mirage.strokecolor(color)
    Mirage.stroke()
end

function main()
    app = MirageApp("Mirage: Orbital Dynamics"; width = 1400, height = 860)
    running = Ref(true)
    timestep = Ref{Float32}(0.001f0)
    gravity = Ref{Float32}(Float32(DEFAULT_G))
    substeps = Ref{Cint}(8)
    trail_length = Ref{Cint}(240)
    labels = Ref(true)
    vectors = Ref(true)
    trails_visible = Ref(true)
    selected = Ref(2)
    dragged = Ref{Union{Nothing, Int}}(nothing)
    panning = Ref(false)
    drag_samples = Tuple{Float64, Vec2}[]
    state = reset_state(Float64(timestep[]) / substeps[])
    laid_out = Ref(false)
    step_requested = Ref(false)
    reset_requested = Ref(false)
    reset_view_requested = Ref(false)
    zoom = Ref{Float32}(42.0f0)
    camera_center = Ref{Vec2}((0.0, 0.0))
    pan_start_mouse = Ref((0.0, 0.0))
    pan_start_center = Ref{Vec2}((0.0, 0.0))
    canvas_hovered = Ref(false)
    canvas_size = Ref((1.0, 1.0))
    canvas_mouse = Ref((0.0, 0.0))
    reference_energy = Ref(total_energy(state; G = gravity[]))
    reference_gravity = Ref(gravity[])

    # Zoom around the point under the cursor, not merely the canvas center. Canvas
    # metadata comes from the preceding frame because GLFW dispatches scroll before
    # the next ImGui frame begins.
    set_scroll_callback!(app) do _window, _xoff, yoff
        canvas_hovered[] || return
        old_zoom = Float64(zoom[])
        new_zoom = clamp(old_zoom * exp(0.14 * Float64(yoff)), 8.0, 220.0)
        width, height = canvas_size[]
        mouse = canvas_mouse[]
        camera_center[] = zoom_camera_at(camera_center[], mouse, width, height,
                                         old_zoom, new_zoom)
        zoom[] = Float32(new_zoom)
        request_frame!(app)
    end

    run!(app; animate = _ -> running[], menu_bar = true) do a
        if !laid_out[]
            dock_layout!(a; center = "Simulation", left = "Controls", right = "Inspector",
                         left_size = 0.19, right_size = 0.26)
            laid_out[] = true
        end

        if CImGui.BeginMenuBar()
            if CImGui.BeginMenu("Simulation")
                CImGui.MenuItem(running[] ? "Pause" : "Run") && (running[] = !running[])
                CImGui.MenuItem("Step", "", false, !running[]) && (step_requested[] = true)
                CImGui.MenuItem("Reset") && (reset_requested[] = true)
                CImGui.MenuItem("Exit") && stop!(a)
                CImGui.EndMenu()
            end
            if CImGui.BeginMenu("View")
                CImGui.MenuItem("Labels", "", labels)
                CImGui.MenuItem("Velocity vectors", "", vectors)
                CImGui.MenuItem("Trails", "", trails_visible)
                CImGui.MenuItem("Reset camera") && (reset_view_requested[] = true)
                CImGui.EndMenu()
            end
            CImGui.EndMenuBar()
        end

        CImGui.Begin("Controls")
        if CImGui.Button(running[] ? "Pause" : "Run")
            running[] = !running[]
        end
        CImGui.SameLine()
        if CImGui.Button("Step") && !running[]
            step_requested[] = true
        end
        CImGui.SameLine()
        CImGui.Button("Reset") && (reset_requested[] = true)
        if CImGui.Button("Reset camera")
            reset_view_requested[] = true
        end
        CImGui.Separator()
        CImGui.SliderFloat("frame dt", timestep, 0.001f0, 0.02f0, "%.4f")
        CImGui.SliderFloat("gravity", gravity, 0.1f0, 2.0f0, "%.2f")
        CImGui.SliderInt("substeps", substeps, 1, 32)
        CImGui.SliderInt("trail length", trail_length, 20, 600)
        CImGui.SliderFloat("zoom", zoom, 8.0f0, 220.0f0, "%.0f px/unit")
        CImGui.Checkbox("labels", labels)
        CImGui.Checkbox("velocity vectors", vectors)
        CImGui.Checkbox("trails", trails_visible)
        CImGui.Separator()
        CImGui.TextWrapped("Drag a body to reposition and throw it. Drag empty space to pan. Scroll over the canvas to zoom around the cursor.")
        CImGui.End()

        if gravity[] != reference_gravity[]
            reference_gravity[] = gravity[]
            reference_energy[] = total_energy(state; G = gravity[])
        end
        if reset_requested[]
            reset!(state, Float64(timestep[]) / substeps[])
            selected[] = 2
            dragged[] = nothing
            panning[] = false
            empty!(drag_samples)
            reference_energy[] = total_energy(state; G = gravity[])
            reset_requested[] = false
        end
        if reset_view_requested[]
            camera_center[] = (0.0, 0.0)
            zoom[] = 42.0f0
            reset_view_requested[] = false
        end
        if running[] || step_requested[]
            advance!(state, timestep[]; substeps = substeps[], G = gravity[],
                     dragged = dragged[], trail_length = trail_length[])
            step_requested[] = false
        end

        CImGui.Begin("Inspector")
        if CImGui.BeginCombo("body", state.bodies[selected[]].name)
            for (i, body) in pairs(state.bodies)
                if CImGui.Selectable(body.name, i == selected[])
                    selected[] = i
                end
            end
            CImGui.EndCombo()
        end
        body = state.bodies[selected[]]
        velocity = body_velocity(state, selected[])
        acceleration = total_acceleration(state.bodies, selected[]; G = gravity[])
        contributions = acceleration_contributions(state.bodies, selected[]; G = gravity[])
        dominant = isempty(contributions) ? nothing :
                   first(contributions[argmax(map(p -> vnorm(last(p)), contributions))])
        CImGui.Text("mass: $(round(body.mass; digits = 4))")
        CImGui.Text("position: ($(round(body.position[1]; digits = 3)), $(round(body.position[2]; digits = 3)))")
        CImGui.Text("velocity: ($(round(velocity[1]; digits = 3)), $(round(velocity[2]; digits = 3)))")
        CImGui.Text("speed: $(round(vnorm(velocity); digits = 3))")
        CImGui.Text("total acceleration: $(round(vnorm(acceleration); digits = 4))")
        if dominant !== nothing
            CImGui.Text("dominant: $(state.bodies[dominant].name)")
        end
        system_energy = total_energy(state; G = gravity[])
        energy_drift = abs(system_energy - reference_energy[]) /
                       max(abs(reference_energy[]), eps(Float64))
        system_momentum = vnorm(momentum(state))
        CImGui.Separator()
        CImGui.Text("System diagnostics")
        CImGui.Text("simulation time: $(round(state.time; digits = 3))")
        CImGui.Text("total energy: $(round(system_energy; sigdigits = 6))")
        if dragged[] === nothing
            CImGui.Text("relative energy drift: $(round(energy_drift; sigdigits = 4))")
        else
            CImGui.Text("relative energy drift: -- while dragging")
        end
        CImGui.Text("momentum magnitude: $(round(system_momentum; sigdigits = 5))")
        CImGui.TextWrapped("The energy baseline resets after a throw or gravity change, so drift reflects integration error rather than your edit.")
        CImGui.Separator()
        CImGui.Text("Gravitational contributions")
        if CImGui.BeginTable("forces", 3, CImGui.ImGuiTableFlags_Borders | CImGui.ImGuiTableFlags_RowBg)
            for (j, contribution) in contributions
                CImGui.TableNextRow()
                CImGui.TableNextColumn(); CImGui.Text(state.bodies[j].name)
                CImGui.TableNextColumn(); CImGui.Text("$(round(contribution[1]; digits = 4))")
                CImGui.TableNextColumn(); CImGui.Text("$(round(contribution[2]; digits = 4))")
            end
            CImGui.EndTable()
        end
        CImGui.End()

        CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowPadding, (0.0f0, 0.0f0))
        CImGui.Begin("Simulation")
        CImGui.PopStyleVar()
        draw_canvas!(a, :orbit; clear_color = (0.025, 0.03, 0.055, 1.0)) do canvas, viewport
            canvas_hovered[] = viewport.hovered
            canvas_size[] = (Float64(canvas.width), Float64(canvas.height))
            canvas_mouse[] = viewport.mouse_rel

            if viewport.clicked
                hit = nearest_body(state, viewport.mouse_rel, canvas.width, canvas.height,
                                   zoom[], camera_center[])
                if hit !== nothing
                    selected[] = hit
                    dragged[] = hit
                    panning[] = false
                    empty!(drag_samples)
                    push!(drag_samples, (time(), state.bodies[hit].position))
                else
                    dragged[] = nothing
                    panning[] = true
                    pan_start_mouse[] = viewport.mouse_rel
                    pan_start_center[] = camera_center[]
                end
            end
            if dragged[] !== nothing && viewport.active
                i = dragged[]
                state.bodies[i].position = screen_to_world(viewport.mouse_rel, canvas.width,
                                                           canvas.height, zoom[], camera_center[])
                state.bodies[i].previous_position = state.bodies[i].position
                push!(drag_samples, (time(), state.bodies[i].position))
                cutoff = time() - 0.12
                while length(drag_samples) > 2 && drag_samples[2][1] < cutoff
                    popfirst!(drag_samples)
                end
            elseif dragged[] !== nothing
                i = dragged[]
                if length(drag_samples) >= 2
                    first_sample, last_sample = first(drag_samples), last(drag_samples)
                    throw_velocity = drag_release_velocity(first_sample[2], last_sample[2],
                                                           last_sample[1] - first_sample[1])
                    set_body_velocity!(state, i, throw_velocity)
                end
                reference_energy[] = total_energy(state; G = gravity[])
                dragged[] = nothing
                empty!(drag_samples)
            end
            if panning[] && viewport.active
                dx = viewport.mouse_rel[1] - pan_start_mouse[][1]
                dy = viewport.mouse_rel[2] - pan_start_mouse[][2]
                camera_center[] = (pan_start_center[][1] - dx / zoom[],
                                   pan_start_center[][2] + dy / zoom[])
            elseif panning[]
                panning[] = false
            end

            if trails_visible[]
                for (trail, trail_body) in zip(state.trails, state.bodies)
                    length(trail) < 2 && continue
                    Mirage.beginpath()
                    for (i, point) in pairs(trail)
                        p = world_to_screen(point, canvas.width, canvas.height, zoom[],
                                            camera_center[])
                        i == 1 ? Mirage.moveto(p...) : Mirage.lineto(p...)
                    end
                    Mirage.strokewidth(1.5)
                    Mirage.strokecolor(trail_body.color)
                    Mirage.stroke()
                end
            end

            for (i, scene_body) in pairs(state.bodies)
                p = world_to_screen(scene_body.position, canvas.width, canvas.height, zoom[],
                                    camera_center[])
                if vectors[]
                    velocity = body_velocity(state, i)
                    draw_arrow((Float64(p[1]), Float64(p[2])),
                               (velocity[1] * 2.2, -velocity[2] * 2.2))
                end
                # Mirage circles are centered on the current transform. Translate
                # explicitly so rendering and hit-testing share the same position.
                Mirage.save()
                Mirage.translate(p...)
                Mirage.fillcolor(scene_body.color)
                Mirage.fillcircle(scene_body.display_radius)
                if i == selected[]
                    Mirage.beginpath()
                    Mirage.circle(scene_body.display_radius + 5)
                    Mirage.strokewidth(2)
                    Mirage.strokecolor(Mirage.rgba(255, 255, 255))
                    Mirage.stroke()
                end
                Mirage.restore()
                if labels[]
                    Mirage.save()
                    Mirage.translate(p[1] + scene_body.display_radius + 5, p[2] - 7)
                    Mirage.fillcolor(Mirage.rgba(225, 232, 245))
                    Mirage.text(scene_body.name)
                    Mirage.restore()
                end
            end
        end
        CImGui.End()
    end
end

end # module OrbitalDynamics

if abspath(PROGRAM_FILE) == @__FILE__
    OrbitalDynamics.main()
end
