# A focused 2D rendering gallery: primitives, paths, transforms, text, a loaded
# image, and an offscreen canvas displayed as an ordinary texture.
#
#   julia --project=examples examples/05_rendering_gallery_2d.jl

module RenderingGallery2D

using Mirage

const ASSET_DIR = joinpath(@__DIR__, "assets")

function draw_card(x, y, width, height, title)
    Mirage.save()
    Mirage.fillcolor(Mirage.rgba(14, 20, 36))
    Mirage.fillrect(x, y, width, height)
    Mirage.beginpath()
    Mirage.rect(x, y, width, height)
    Mirage.strokewidth(2)
    Mirage.strokecolor(Mirage.rgba(45, 61, 91))
    Mirage.stroke()
    Mirage.translate(x + 22, y + 20)
    Mirage.fillcolor(Mirage.rgba(196, 210, 235))
    Mirage.text(title)
    Mirage.restore()
end

function star_points(outer_radius, inner_radius)
    return [
        let angle = -pi / 2 + i * pi / 5
            radius = iseven(i) ? outer_radius : inner_radius
            (radius * cos(angle), radius * sin(angle))
        end for i in 0:9
    ]
end

function draw_star(outer_radius, inner_radius)
    points = star_points(outer_radius, inner_radius)

    # Mirage.fill uses a simple first-vertex fan, which is only generally valid
    # for convex polygons. A star is concave, so explicitly triangulate it from
    # its center (the star is star-convex with respect to that point).
    for i in eachindex(points)
        next_i = i == length(points) ? 1 : i + 1
        Mirage.beginpath()
        Mirage.moveto(0, 0)
        Mirage.lineto(points[i]...)
        Mirage.lineto(points[next_i]...)
        Mirage.closepath()
        Mirage.fillcolor(iseven(i) ? Mirage.rgba(116, 88, 218) :
                                     Mirage.rgba(94, 72, 190))
        Mirage.fill()
    end

    Mirage.beginpath()
    for (i, point) in pairs(points)
        i == 1 ? Mirage.moveto(point...) : Mirage.lineto(point...)
    end
    Mirage.closepath()
    Mirage.strokewidth(5)
    Mirage.strokecolor(Mirage.rgba(214, 204, 255))
    Mirage.stroke()
end

function render_badge!(canvas)
    Mirage.set_canvas(canvas)
    try
        Mirage.clear()
        Mirage.update_ortho_projection_matrix(canvas.width, canvas.height, 1.0)
        Mirage.fillcolor(Mirage.rgba(18, 28, 54))
        Mirage.fillrect(0, 0, canvas.width, canvas.height)
        Mirage.save()
        Mirage.translate(canvas.width / 2, canvas.height / 2 - 18)
        for (radius, color) in zip((82, 62, 42),
                                   ((62, 205, 200), (90, 225, 210), (135, 240, 220)))
            Mirage.beginpath()
            Mirage.circle(radius)
            Mirage.strokewidth(7)
            Mirage.strokecolor(Mirage.rgba(color...))
            Mirage.stroke()
        end
        Mirage.rotate(pi / 4)
        Mirage.fillcolor(Mirage.rgba(255, 190, 86))
        Mirage.fillrect(-18, -18, 36, 36)
        Mirage.restore()
        Mirage.save()
        Mirage.translate(51, 216)
        Mirage.scale(1.9)
        Mirage.fillcolor(Mirage.rgba(245, 250, 255))
        Mirage.text("OFFSCREEN")
        Mirage.restore()
    finally
        Mirage.set_canvas()
    end
end

function gallery_scene!(canvas, image_texture, badge, t)
    margin = 30.0
    gap = 22.0
    header_height = 76.0
    footer_height = 48.0
    column = (canvas.width - 2margin - 2gap) / 3
    card_y = header_height
    card_height = canvas.height - header_height - footer_height
    card_x = (margin, margin + column + gap, margin + 2(column + gap))

    Mirage.save()
    Mirage.translate(margin, 24)
    Mirage.scale(1.35)
    Mirage.fillcolor(Mirage.rgba(235, 242, 255))
    Mirage.text("MIRAGE 2D RENDERING GALLERY")
    Mirage.restore()

    draw_card(card_x[1], card_y, column, card_height, "PRIMITIVES")
    draw_card(card_x[2], card_y, column, card_height, "PATHS + TRANSFORMS")
    draw_card(card_x[3], card_y, column, card_height, "IMAGES + CANVAS")

    # Filled and stroked primitives. Circles are centered through transforms—the
    # current Mirage circle helpers intentionally draw around the local origin.
    left_x = card_x[1]
    inner_width = column - 44
    Mirage.save()
    Mirage.fillcolor(Mirage.rgba(255, 102, 118))
    Mirage.fillrect(left_x + 22, card_y + 68, inner_width, 82)

    Mirage.translate(left_x + column * 0.30, card_y + 245)
    Mirage.fillcolor(Mirage.rgba(82, 171, 245))
    Mirage.fillcircle(min(58, column * 0.14))
    Mirage.restore()

    Mirage.save()
    Mirage.translate(left_x + column * 0.70, card_y + 245)
    Mirage.beginpath()
    Mirage.circle(min(58, column * 0.14))
    Mirage.strokewidth(9)
    Mirage.strokecolor(Mirage.rgba(255, 200, 76))
    Mirage.stroke()
    Mirage.restore()

    Mirage.save()
    Mirage.translate(left_x + column / 2, card_y + 405)
    Mirage.rotate(-0.08)
    Mirage.beginpath()
    Mirage.moveto(-82, 48)
    Mirage.lineto(0, -58)
    Mirage.lineto(82, 48)
    Mirage.closepath()
    Mirage.fillcolor(Mirage.rgba(77, 211, 165))
    Mirage.fill()
    Mirage.strokewidth(4)
    Mirage.strokecolor(Mirage.rgba(172, 250, 218))
    Mirage.stroke()
    Mirage.restore()

    # Concave path, explicitly triangulated, animated through the transform stack.
    middle_x = card_x[2]
    star_radius = min(115.0, column * 0.27)
    Mirage.save()
    Mirage.translate(middle_x + column / 2, card_y + card_height * 0.38)
    Mirage.rotate(0.12sin(t * 0.8))
    Mirage.scale(1.0 + 0.035cos(t))
    draw_star(star_radius, star_radius * 0.46)
    Mirage.restore()

    for i in -1:1
        Mirage.save()
        Mirage.translate(middle_x + column / 2 + i * 84, card_y + card_height * 0.72)
        Mirage.rotate(t * (0.35 + 0.08i))
        Mirage.fillcolor(i == 0 ? Mirage.rgba(255, 166, 84) :
                                  Mirage.rgba(105, 190, 245))
        Mirage.fillrect(-22, -22, 44, 44)
        Mirage.restore()
    end

    # Loaded image and an independently rendered offscreen canvas texture.
    right_x = card_x[3]
    image_size = min(column - 44, (card_height - 145) / 2)
    image_x = right_x + (column - image_size) / 2
    first_y = card_y + 70
    second_y = first_y + image_size + 54

    Mirage.save()
    Mirage.translate(image_x, first_y - 24)
    Mirage.fillcolor(Mirage.rgba(150, 172, 208))
    Mirage.text("LOADED JPEG")
    Mirage.restore()
    Mirage.drawimage(image_x, first_y, image_size, image_size, image_texture)
    Mirage.beginpath()
    Mirage.rect(image_x, first_y, image_size, image_size)
    Mirage.strokewidth(2)
    Mirage.strokecolor(Mirage.rgba(71, 91, 126))
    Mirage.stroke()

    Mirage.save()
    Mirage.translate(image_x, second_y - 24)
    Mirage.fillcolor(Mirage.rgba(150, 172, 208))
    Mirage.text("OFFSCREEN CANVAS TEXTURE")
    Mirage.restore()
    Mirage.drawimage(image_x, second_y, image_size, image_size, badge.texture)
    Mirage.beginpath()
    Mirage.rect(image_x, second_y, image_size, image_size)
    Mirage.strokewidth(2)
    Mirage.strokecolor(Mirage.rgba(71, 91, 126))
    Mirage.stroke()

    Mirage.save()
    Mirage.translate(margin, canvas.height - 30)
    Mirage.fillcolor(Mirage.rgba(147, 171, 210))
    Mirage.text("FILLS  /  STROKES  /  PATHS  /  TRANSFORMS  /  TEXT  /  TEXTURES")
    Mirage.restore()
end

function main()
    app = MirageApp("Mirage: 2D Rendering Gallery"; width = 1180, height = 760)
    image_texture = UInt32(0)
    badge = nothing
    start_time = time()
    run_started = false

    try
        image_texture = Mirage.load_texture(joinpath(ASSET_DIR, "testimage.jpg"))
        badge = Mirage.create_canvas(256, 256)
        render_badge!(badge)

        cleanup = function (_app)
            image_texture == 0 || Mirage.destroy_texture!(image_texture)
            badge === nothing || Mirage.destroy!(badge)
            return nothing
        end

        run_started = true
        run!(app; animate = true, cleanup! = cleanup) do a
            draw_background_canvas!(a, :gallery;
                                    clear_color = (0.035, 0.04, 0.065, 1.0)) do canvas, _
                gallery_scene!(canvas, image_texture, badge, time() - start_time)
            end
        end
    catch
        if !run_started
            try
                image_texture == 0 || Mirage.destroy_texture!(image_texture)
                badge === nothing || Mirage.destroy!(badge)
                Mirage.destroy!(app)
            catch
            end
        end
        rethrow()
    end
    return nothing
end

end # module RenderingGallery2D

if abspath(PROGRAM_FILE) == @__FILE__
    RenderingGallery2D.main()
end
