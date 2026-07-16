# Mirage.jl

Mirage is a hardware-accelerated 2D and 3D graphics library for Julia. It combines
an HTML5 Canvas-style drawing API with Dear ImGui and GLFW desktop windows.

Use it for simulations, visual tools, and custom desktop applications. Mirage is
used in SHERPA, a lunar mission-planning tool at NASA Ames.

## Features

- [`MirageApp`](@ref) windows with docking and ImGui panels
- Immediate-mode shapes, paths, text, images, and transforms
- Meshes, OBJ loading, perspective cameras, and custom shaders
- Event-driven or continuous rendering
- Revise-based live reload with [`run_live!`](@ref)

## Guides

- [Getting Started](getting_started.md)
- [Core Concepts](concepts.md)
- [Examples](examples.md)
- [API Reference](api_reference.md)
