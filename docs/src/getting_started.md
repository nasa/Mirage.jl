# Getting Started

Mirage requires Julia 1.11 or newer.

## Install

```julia
import Pkg
Pkg.add(url = "https://github.com/nasa/Mirage.jl")
```

## Open a window

```julia
using Mirage

app = MirageApp("Spinning Square"; width = 800, height = 600)

run!(app; animate = true) do a
    draw_background_canvas!(a) do canvas, _
        Mirage.save()
        Mirage.translate(canvas.width / 2, canvas.height / 2)
        Mirage.rotate(time())
        Mirage.fillcolor(Mirage.rgba(255, 70, 70))
        Mirage.fillrect(-55, -55, 110, 110)
        Mirage.restore()
    end
end
```

Application functions such as `run!` are exported. Drawing functions are qualified,
for example `Mirage.fillrect` and `Mirage.rotate`.

`run!` is event-driven by default. Use `animate = true` for continuous motion.

## Run the examples

```sh
git clone https://github.com/nasa/Mirage.jl
cd Mirage.jl
julia --project=examples -e 'using Pkg; Pkg.instantiate()'
julia --project=examples examples/01_minimal_app.jl
```

## Live reload

Load Revise before your app, then use [`run_live!`](@ref):

```julia
using Revise
using MyApp
MyApp.main()
```

For a loose script, use `includet("myapp.jl")`. See
`examples/02_live_reload.jl`.
