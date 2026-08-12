# API Reference

## Desktop applications

```@docs
MirageApp
CanvasViewport
run!
run_live!
request_frame!
stop!
draw_canvas!
draw_background_canvas!
dock_layout!
```

## Advanced application lifecycle

These functions expose the machinery used by the primary application helpers.
Most applications should use `run!`, `draw_canvas!`, and
`draw_background_canvas!` instead.

```@docs
Mirage.begin_frame!
Mirage.end_frame!
Mirage.live_revise!
Mirage.get_canvas!
Mirage.resize_canvas!
Mirage.destroy_canvas!
Mirage.draw_canvas_image!
Mirage.begin_dockspace!
Mirage.end_dockspace!
```

## Canvas drawing

```@docs
Mirage.beginpath
Mirage.moveto
Mirage.lineto
Mirage.closepath
Mirage.rect
Mirage.circle
Mirage.fill
Mirage.stroke
Mirage.fillrect
Mirage.fillcircle
Mirage.drawimage
Mirage.text
Mirage.fillcolor
Mirage.strokecolor
Mirage.strokewidth
Mirage.rgba
Mirage.save
Mirage.restore
Mirage.translate
Mirage.scale
Mirage.rotate
Mirage.lookat
Mirage.clear
```

## Canvases and textures

```@docs
Mirage.Canvas
Mirage.create_canvas
Mirage.set_canvas
Mirage.resize!
Mirage.destroy!
Mirage.load_texture
Mirage.destroy_texture!
```

## Meshes and custom rendering

```@docs
Mirage.Mesh
Mirage.VertexAttribute
Mirage.create_mesh
Mirage.update_mesh_vertices!
Mirage.draw_mesh
Mirage.create_cube
Mirage.create_uv_sphere
Mirage.load_obj_mesh
Mirage.create_shader_program
Mirage.set_uniform
Mirage.update_ortho_projection_matrix
Mirage.update_perspective_projection_matrix
```

## OpenGL embedding

```@docs
Mirage.initialize_render_context
Mirage.cleanup_render_context
```
