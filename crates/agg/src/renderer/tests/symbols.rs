use super::*;

#[test]
fn swash_renders_mosaic_symbols_crunchy() {
    let mut renderer = swash(settings(false));
    let input = concat!(
        "\x1b[38;5;2m",
        "\u{2503}\u{2579}\u{257b}\u{2580}\u{259a}\u{25a0}\u{1fb00}\u{1fb3b}",
        "\x1b[39m",
        "\r\n",
        "\x1b[38;5;6m██\x1b[39m",
        "\r\n",
        "\x1b[38;5;1m░▒▓\x1b[39m",
        "\r\n",
        "\x1b[2m█\x1b[22m",
        "\r\n",
        "\x1b[38;5;4m─│╴╵╶╷\x1b[39m",
        "\r\n",
        "\x1b[38;5;5m━┃╸╹╺╻\x1b[39m",
        "\r\n",
        "\x1b[38;5;6m┌┐└┘┏┓┗┛\x1b[39m",
        "\r\n",
        "\x1b[38;5;3m┡┩┳┴╇\x1b[39m",
    );
    let image = render(&mut renderer, lines_for(input), None);

    // Heavy vertical and half-lines use centered crisp strokes.
    assert_rgb_close(cell_pixel(&image, 0, 0, 0.5, 0.5), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 0, 0, 0.34, 0.5), BG, 0);
    assert_rgb_close(cell_pixel(&image, 0, 0, 0.1, 0.5), BG, 0);
    assert_rgb_close(cell_pixel(&image, 1, 0, 0.5, 0.25), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 1, 0, 0.5, 0.75), BG, 0);
    assert_rgb_close(cell_pixel(&image, 2, 0, 0.5, 0.46), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 2, 0, 0.5, 0.25), BG, 0);
    assert_rgb_close(cell_pixel(&image, 2, 0, 0.5, 0.75), PALETTE[GREEN], 0);

    // Blocks, quadrants, and black square are cell-aligned geometry.
    assert_rgb_close(cell_pixel(&image, 3, 0, 0.5, 0.25), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 3, 0, 0.5, 0.75), BG, 0);
    assert_rgb_close(cell_pixel(&image, 4, 0, 0.25, 0.25), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 4, 0, 0.75, 0.25), BG, 0);
    assert_rgb_close(cell_pixel(&image, 4, 0, 0.25, 0.75), BG, 0);
    assert_rgb_close(cell_pixel(&image, 4, 0, 0.75, 0.75), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 5, 0, 0.5, 0.1), BG, 0);
    assert_rgb_close(cell_pixel(&image, 5, 0, 0.5, 0.5), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 5, 0, 0.5, 0.9), BG, 0);

    // Sextants use 2x3 cell granularity, including the Unicode gap mapping.
    assert_rgb_close(cell_pixel(&image, 6, 0, 0.25, 0.16), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 6, 0, 0.75, 0.16), BG, 0);
    assert_rgb_close(cell_pixel(&image, 6, 0, 0.25, 0.5), BG, 0);
    assert_rgb_close(cell_pixel(&image, 7, 0, 0.25, 0.16), BG, 0);
    assert_rgb_close(cell_pixel(&image, 7, 0, 0.75, 0.16), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 7, 0, 0.25, 0.5), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 7, 0, 0.75, 0.5), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 7, 0, 0.25, 0.84), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 7, 0, 0.75, 0.84), PALETTE[GREEN], 0);

    // Adjacent full blocks must not leave a seam between cells.
    assert_rgb_close(cell_pixel(&image, 0, 1, 0.98, 0.5), PALETTE[CYAN], 0);
    assert_rgb_close(cell_pixel(&image, 1, 1, 0.02, 0.5), PALETTE[CYAN], 0);

    // Shades blend the foreground over the already-painted background.
    assert_rgb_close(
        cell_center(&image, 0, 2),
        blend_rgb(PALETTE[RED], BG, 64),
        0,
    );
    assert_rgb_close(
        cell_center(&image, 1, 2),
        blend_rgb(PALETTE[RED], BG, 128),
        0,
    );
    assert_rgb_close(
        cell_center(&image, 2, 2),
        blend_rgb(PALETTE[RED], BG, 192),
        0,
    );

    // Faint = half intensity.
    assert_rgb_close(cell_center(&image, 0, 3), blend_rgb(FG, BG, 127), 0);

    // Box drawing light lines use the font-derived light stroke.
    assert_rgb_close(cell_pixel(&image, 0, 4, 0.5, 0.46), PALETTE[BLUE], 0);
    assert_rgb_close(cell_pixel(&image, 0, 4, 0.5, 0.4), BG, 0);
    assert_rgb_close(cell_pixel(&image, 1, 4, 0.42, 0.5), PALETTE[BLUE], 0);
    assert_rgb_close(cell_pixel(&image, 1, 4, 0.58, 0.5), BG, 0);
    assert_rgb_close(cell_pixel(&image, 2, 4, 0.25, 0.46), PALETTE[BLUE], 0);
    assert_rgb_close(cell_pixel(&image, 2, 4, 0.75, 0.46), BG, 0);
    assert_rgb_close(cell_pixel(&image, 3, 4, 0.42, 0.25), PALETTE[BLUE], 0);
    assert_rgb_close(cell_pixel(&image, 3, 4, 0.42, 0.75), BG, 0);
    assert_rgb_close(cell_pixel(&image, 4, 4, 0.75, 0.46), PALETTE[BLUE], 0);
    assert_rgb_close(cell_pixel(&image, 4, 4, 0.25, 0.46), BG, 0);
    assert_rgb_close(cell_pixel(&image, 5, 4, 0.42, 0.75), PALETTE[BLUE], 0);
    assert_rgb_close(cell_pixel(&image, 5, 4, 0.42, 0.25), BG, 0);

    // Box drawing heavy horizontal lines and half-lines mirror vertical strokes.
    assert_rgb_close(cell_pixel(&image, 0, 5, 0.5, 0.5), PALETTE[MAGENTA], 0);
    assert_rgb_close(cell_pixel(&image, 0, 5, 0.5, 0.4), BG, 0);
    assert_rgb_close(cell_pixel(&image, 2, 5, 0.25, 0.5), PALETTE[MAGENTA], 0);
    assert_rgb_close(cell_pixel(&image, 2, 5, 0.75, 0.5), BG, 0);
    assert_rgb_close(cell_pixel(&image, 4, 5, 0.75, 0.5), PALETTE[MAGENTA], 0);
    assert_rgb_close(cell_pixel(&image, 4, 5, 0.25, 0.5), BG, 0);

    // All-light and all-heavy corners join cleanly through the center.
    assert_rgb_close(cell_pixel(&image, 0, 6, 0.75, 0.46), PALETTE[CYAN], 0);
    assert_rgb_close(cell_pixel(&image, 0, 6, 0.42, 0.75), PALETTE[CYAN], 0);
    assert_rgb_close(cell_pixel(&image, 0, 6, 0.25, 0.25), BG, 0);
    assert_rgb_close(cell_pixel(&image, 4, 6, 0.75, 0.5), PALETTE[CYAN], 0);
    assert_rgb_close(cell_pixel(&image, 4, 6, 0.5, 0.75), PALETTE[CYAN], 0);
    assert_rgb_close(cell_pixel(&image, 4, 6, 0.25, 0.25), BG, 0);

    // Mixed-weight junctions used by emoji.pop are rendered as crisp geometry.
    assert_rgb_close(cell_pixel(&image, 0, 7, 0.5, 0.25), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 0, 7, 0.75, 0.5), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 0, 7, 0.42, 0.75), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 0, 7, 0.25, 0.5), BG, 0);
    assert_rgb_close(cell_pixel(&image, 1, 7, 0.5, 0.25), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 1, 7, 0.25, 0.5), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 1, 7, 0.42, 0.75), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 1, 7, 0.75, 0.5), BG, 0);
    assert_rgb_close(cell_pixel(&image, 2, 7, 0.25, 0.5), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 2, 7, 0.75, 0.5), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 2, 7, 0.5, 0.75), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 2, 7, 0.5, 0.25), BG, 0);
    assert_rgb_close(cell_pixel(&image, 3, 7, 0.25, 0.46), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 3, 7, 0.75, 0.46), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 3, 7, 0.42, 0.25), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 3, 7, 0.42, 0.75), BG, 0);
    assert_rgb_close(cell_pixel(&image, 4, 7, 0.5, 0.25), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 4, 7, 0.75, 0.5), PALETTE[YELLOW], 0);
    assert_rgb_close(cell_pixel(&image, 4, 7, 0.42, 0.75), PALETTE[YELLOW], 0);
}

#[test]
fn swash_renders_powerline_symbols_as_cell_geometry() {
    let mut renderer = swash(settings_without_symbol_fallback());

    let image = render(
        &mut renderer,
        lines_for(concat!(
            "\x1b[38;5;2m",
            "\u{e0b0}\u{e0b1}\u{e0b2}\u{e0b3}",
            "\u{e0b4}\u{e0b5}\u{e0b6}\u{e0b7}",
            "\u{e0b8}\u{e0b9}\u{e0ba}\u{e0bb}",
            "\u{e0bc}\u{e0bd}\u{e0be}\u{e0bf}",
            "\x1b[39m",
        )),
        None,
    );

    for (col, x, y) in [
        (0, 0.25, 0.50),  // right full triangle
        (1, 0.50, 0.25),  // right bracket
        (2, 0.75, 0.50),  // left full triangle
        (3, 0.50, 0.25),  // left bracket
        (4, 0.50, 0.50),  // right thick cap
        (5, 0.85, 0.25),  // right thin cap
        (6, 0.50, 0.50),  // left thick cap
        (7, 0.12, 0.25),  // left thin cap
        (8, 0.25, 0.75),  // lower-left triangle
        (9, 0.50, 0.50),  // backslash
        (10, 0.75, 0.75), // lower-right triangle
        (11, 0.50, 0.50), // forward slash
        (12, 0.25, 0.25), // upper-left triangle
        (13, 0.50, 0.50), // redundant forward slash
        (14, 0.75, 0.25), // upper-right triangle
        (15, 0.50, 0.50), // redundant backslash
    ] {
        let actual = cell_pixel(&image, col, 0, x, y);
        let ink = rgb_distance(actual, BG);

        assert!(
            ink > 40,
            "expected powerline cell {col} at ({x}, {y}) to have green ink, got {actual:?}",
        );
    }

    for (col, x, y) in [
        (0, 0.85, 0.15),  // right full triangle
        (1, 0.25, 0.50),  // right bracket interior
        (2, 0.15, 0.15),  // left full triangle
        (3, 0.75, 0.50),  // left bracket interior
        (4, 0.90, 0.10),  // right thick cap corner
        (5, 0.50, 0.50),  // right thin cap interior
        (6, 0.10, 0.10),  // left thick cap corner
        (7, 0.50, 0.50),  // left thin cap interior
        (8, 0.90, 0.10),  // lower-left triangle
        (9, 0.90, 0.10),  // backslash off diagonal
        (10, 0.10, 0.10), // lower-right triangle
        (11, 0.10, 0.10), // forward slash off diagonal
        (12, 0.90, 0.90), // upper-left triangle
        (13, 0.90, 0.90), // redundant forward slash off diagonal
        (14, 0.10, 0.90), // upper-right triangle
        (15, 0.10, 0.90), // redundant backslash off diagonal
    ] {
        let actual = cell_pixel(&image, col, 0, x, y);

        assert!(
            rgb_distance(actual, BG) <= 4,
            "expected powerline cell {col} at ({x}, {y}) to stay background, got {actual:?}",
        );
    }
}

#[test]
fn swash_heavy_box_corners_join_without_notches() {
    let mut settings = settings(false);
    settings.font_size = 40;
    let mut renderer = swash(settings);
    let image = render(&mut renderer, lines_for("\x1b[38;5;2m┏\x1b[39m"), None);

    assert_rgb_close(cell_pixel(&image, 0, 0, 0.42, 0.5), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 0, 0, 0.5, 0.46), PALETTE[GREEN], 0);
    assert_rgb_close(cell_pixel(&image, 0, 0, 0.25, 0.25), BG, 0);
}
