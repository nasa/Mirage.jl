# Mirage.jl

A hardware-accelerated 2D & 3D graphics library for Julia with an HTML5 Canvas–style
API, plus a batteries-included application layer for building standalone desktop GUI
apps on top of Dear ImGui (via CImGui.jl) and GLFW.

## Overview

Mirage.jl provides a simple and productive way to create real-time graphics and the
desktop applications around them. It is designed for developers, researchers, and
engineers who want to visualize algorithms, render simulations, or build custom
interactive tools without the overhead of a large engine or a web stack. The drawing
API is heavily inspired by the HTML5 Canvas; the application layer wires OpenGL,
Dear ImGui, and GLFW together so a full GUI app starts with one constructor. This,
combined with Julia's REPL-driven development and Revise-powered live reloading,
makes GUI iteration feel like ordinary Julia development.

Mirage.jl is used in production in SHERPA, a lunar surface mission-planning tool at
the NASA Ames Research Center.

### Key Features

- **Desktop application layer**: `MirageApp` + `run!` give you a window, ImGui
  context, docking, DPI-scaled fonts, and canvas-in-window rendering with
  `draw_canvas!` and `draw_background_canvas!`.
- **Immediate-mode 2D API**: `Mirage.fillrect`, `Mirage.stroke`, `Mirage.translate`,
  `Mirage.rotate` — if you know the HTML5 Canvas, you'll feel right at home.
- **Simple 3D rendering**: load `.obj` models or create procedural meshes, position
  them with a perspective/lookat camera, or drop down to custom shaders.
- **REPL live reload**: `run_live!` hot-reloads your code while the app runs (via a
  Revise package extension), and frame errors are logged and skipped, not fatal.
- **State management**: a stack-based graphics state (`Mirage.save()` /
  `Mirage.restore()`) for transformations and styles.

### Navigation

- **[Getting Started](getting_started.md)**: install Mirage.jl and open your first app window.
- **[Core Concepts](concepts.md)**: the immediate-mode paradigm, the app layer, canvases, and the state stack.
- **[API Reference](api_reference.md)**: a detailed breakdown of all functions and types.
- **[Examples](examples.md)**: runnable example apps and annotated snippets.
