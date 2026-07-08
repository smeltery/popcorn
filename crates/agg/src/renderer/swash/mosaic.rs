use rgb::RGBA8;

use crate::renderer::TextAttrs;

use super::{blend_straight_alpha, CellLayout, SwashRenderer};

#[derive(Clone, Copy)]
enum BoxLineStyle {
    Light,
    Heavy,
}

#[derive(Clone, Copy)]
struct BoxLineGlyph {
    up: Option<BoxLineStyle>,
    right: Option<BoxLineStyle>,
    down: Option<BoxLineStyle>,
    left: Option<BoxLineStyle>,
}

impl SwashRenderer {
    fn line_thickness(&self, style: BoxLineStyle) -> usize {
        let light = self.box_thickness();

        match style {
            BoxLineStyle::Light => light,
            BoxLineStyle::Heavy => light.saturating_mul(2),
        }
    }

    fn paint_box_lines(
        &self,
        buf: &mut [RGBA8],
        layout: CellLayout,
        fg: RGBA8,
        faint: bool,
        glyph: BoxLineGlyph,
    ) {
        let cell_w = layout.x_r.saturating_sub(layout.x_l);
        let cell_h = layout.y_b.saturating_sub(layout.y_t);
        let light_w = self.box_thickness().min(cell_w);
        let light_h = self.box_thickness().min(cell_h);
        let center_x_l = layout.x_l + (cell_w.saturating_sub(light_w)) / 2;
        let center_x_r = center_x_l + light_w;
        let center_y_t = layout.y_t + (cell_h.saturating_sub(light_h)) / 2;
        let center_y_b = center_y_t + light_h;

        let stroke_x = |style| {
            let stroke_w = self.line_thickness(style).min(cell_w);
            let x_l = layout.x_l + (cell_w - stroke_w) / 2;

            (x_l, x_l + stroke_w)
        };

        let stroke_y = |style| {
            let stroke_h = self.line_thickness(style).min(cell_h);
            let y_t = layout.y_t + (cell_h - stroke_h) / 2;

            (y_t, y_t + stroke_h)
        };

        let up_x = glyph.up.map(stroke_x);
        let down_x = glyph.down.map(stroke_x);
        let right_y = glyph.right.map(stroke_y);
        let left_y = glyph.left.map(stroke_y);

        let vertical_l = [up_x, down_x]
            .into_iter()
            .flatten()
            .map(|(x_l, _)| x_l)
            .min();

        let vertical_r = [up_x, down_x]
            .into_iter()
            .flatten()
            .map(|(_, x_r)| x_r)
            .max();

        let horizontal_t = [right_y, left_y]
            .into_iter()
            .flatten()
            .map(|(y_t, _)| y_t)
            .min();

        let horizontal_b = [right_y, left_y]
            .into_iter()
            .flatten()
            .map(|(_, y_b)| y_b)
            .max();

        if let Some((v_l, v_r)) = up_x {
            let up_bottom = horizontal_b.unwrap_or(center_y_b);

            self.paint_cell_rect(buf, (v_l, layout.y_t, v_r, up_bottom), fg, faint);
        }

        if let Some((h_t, h_b)) = right_y {
            let right_left = vertical_l.unwrap_or(center_x_l);

            self.paint_cell_rect(buf, (right_left, h_t, layout.x_r, h_b), fg, faint);
        }

        if let Some((v_l, v_r)) = down_x {
            let down_top = horizontal_t.unwrap_or(center_y_t);

            self.paint_cell_rect(buf, (v_l, down_top, v_r, layout.y_b), fg, faint);
        }

        if let Some((h_t, h_b)) = left_y {
            let left_right = vertical_r.unwrap_or(center_x_r);

            self.paint_cell_rect(buf, (layout.x_l, h_t, left_right, h_b), fg, faint);
        }
    }

    pub(super) fn paint_mosaic_symbol(
        &self,
        buf: &mut [RGBA8],
        ch: char,
        layout: CellLayout,
        attrs: &TextAttrs,
        fg: RGBA8,
    ) -> bool {
        let cp = ch as u32;
        let full = (layout.x_l, layout.y_t, layout.x_r, layout.y_b);
        let x = |n, d| split(layout.x_l, layout.x_r, n, d);
        let y = |n, d| split(layout.y_t, layout.y_b, n, d);
        let unit_x = |n| x(n, 8);
        let unit_y = |n| y(n, 8);
        let half_x = x(1, 2);
        let half_y = y(1, 2);

        use BoxLineStyle::{Heavy, Light};

        macro_rules! box_lines {
            ($up:expr, $right:expr, $down:expr, $left:expr) => {
                self.paint_box_lines(
                    buf,
                    layout,
                    fg,
                    attrs.faint,
                    BoxLineGlyph {
                        up: $up,
                        right: $right,
                        down: $down,
                        left: $left,
                    },
                )
            };
        }

        match cp {
            // box drawings light/heavy horizontal and vertical
            0x2500 => box_lines!(None, Some(Light), None, Some(Light)),
            0x2501 => box_lines!(None, Some(Heavy), None, Some(Heavy)),
            0x2502 => box_lines!(Some(Light), None, Some(Light), None),
            0x2503 => box_lines!(Some(Heavy), None, Some(Heavy), None),

            // box drawings light/heavy corners
            0x250C => box_lines!(None, Some(Light), Some(Light), None),
            0x250F => box_lines!(None, Some(Heavy), Some(Heavy), None),
            0x2510 => box_lines!(None, None, Some(Light), Some(Light)),
            0x2513 => box_lines!(None, None, Some(Heavy), Some(Heavy)),
            0x2514 => box_lines!(Some(Light), Some(Light), None, None),
            0x2517 => box_lines!(Some(Heavy), Some(Heavy), None, None),
            0x2518 => box_lines!(Some(Light), None, None, Some(Light)),
            0x251B => box_lines!(Some(Heavy), None, None, Some(Heavy)),

            // box drawings mixed junctions used by Rich tables
            0x2521 => box_lines!(Some(Heavy), Some(Heavy), Some(Light), None),
            0x2529 => box_lines!(Some(Heavy), None, Some(Light), Some(Heavy)),
            0x2533 => box_lines!(None, Some(Heavy), Some(Heavy), Some(Heavy)),
            0x2534 => box_lines!(Some(Light), Some(Light), None, Some(Light)),
            0x2547 => box_lines!(Some(Heavy), Some(Heavy), Some(Light), Some(Heavy)),

            // box drawings light/heavy half-lines
            0x2574 => box_lines!(None, None, None, Some(Light)),
            0x2575 => box_lines!(Some(Light), None, None, None),
            0x2576 => box_lines!(None, Some(Light), None, None),
            0x2577 => box_lines!(None, None, Some(Light), None),
            0x2578 => box_lines!(None, None, None, Some(Heavy)),
            0x2579 => box_lines!(Some(Heavy), None, None, None),
            0x257A => box_lines!(None, Some(Heavy), None, None),
            0x257B => box_lines!(None, None, Some(Heavy), None),

            // upper half block
            0x2580 => self.paint_cell_rect(
                buf,
                (layout.x_l, layout.y_t, layout.x_r, half_y),
                fg,
                attrs.faint,
            ),

            // lower N eighths blocks ▁▂▃▄▅▆▇█ (n=8 places top edge at y_t)
            0x2581..=0x2588 => {
                let n = (cp - 0x2580) as usize;

                self.paint_cell_rect(
                    buf,
                    (layout.x_l, unit_y(8 - n), layout.x_r, layout.y_b),
                    fg,
                    attrs.faint,
                );
            }

            // left N eighths blocks ▉▊▋▌▍▎▏
            0x2589..=0x258F => {
                let n = (cp - 0x2588) as usize;

                self.paint_cell_rect(
                    buf,
                    (layout.x_l, layout.y_t, unit_x(8 - n), layout.y_b),
                    fg,
                    attrs.faint,
                );
            }

            // right half block
            0x2590 => self.paint_cell_rect(
                buf,
                (half_x, layout.y_t, layout.x_r, layout.y_b),
                fg,
                attrs.faint,
            ),

            // light, medium, dark shade ░▒▓
            0x2591..=0x2593 => {
                let n = (cp - 0x2590) as u8;
                let ratio = if attrs.faint { 32 * n } else { 64 * n };

                self.paint_cell_rect_alpha(buf, full, fg, ratio);
            }

            // upper one eighth block
            0x2594 => self.paint_cell_rect(
                buf,
                (layout.x_l, layout.y_t, layout.x_r, unit_y(1)),
                fg,
                attrs.faint,
            ),

            // right one eighth block
            0x2595 => self.paint_cell_rect(
                buf,
                (unit_x(7), layout.y_t, layout.x_r, layout.y_b),
                fg,
                attrs.faint,
            ),

            // quadrant blocks ▖▗▘▙▚▛▜▝▞▟ (Unicode order doesn't match any
            // quadrant-bit pattern, so look up each combination)
            0x2596..=0x259F => {
                // Bits, top-to-bottom, left-to-right: 0b1=UL 0b10=UR 0b100=LL 0b1000=LR
                const QUADRANTS: [u8; 10] = [
                    0b0100, // ▖ lower left
                    0b1000, // ▗ lower right
                    0b0001, // ▘ upper left
                    0b1101, // ▙ ul + ll + lr
                    0b1001, // ▚ ul + lr
                    0b0111, // ▛ ul + ur + ll
                    0b1011, // ▜ ul + ur + lr
                    0b0010, // ▝ upper right
                    0b0110, // ▞ ur + ll
                    0b1110, // ▟ ur + ll + lr
                ];

                let mask = QUADRANTS[(cp - 0x2596) as usize];

                self.paint_quadrants(buf, layout, fg, attrs.faint, mask);
            }

            // black square, rendered as a centered half-height mosaic block
            0x25A0 => self.paint_cell_rect(
                buf,
                (layout.x_l, unit_y(2), layout.x_r, unit_y(6)),
                fg,
                attrs.faint,
            ),

            cp => {
                let Some(mask) = sextant_mask(cp) else {
                    return false;
                };

                self.paint_sextants(buf, layout, fg, attrs.faint, mask);
            }
        }

        true
    }

    fn paint_quadrants(
        &self,
        buf: &mut [RGBA8],
        layout: CellLayout,
        fg: RGBA8,
        faint: bool,
        mask: u8,
    ) {
        let half_x = split(layout.x_l, layout.x_r, 1, 2);
        let half_y = split(layout.y_t, layout.y_b, 1, 2);

        if (mask & 0b0001) != 0 {
            self.paint_cell_rect(buf, (layout.x_l, layout.y_t, half_x, half_y), fg, faint);
        }

        if (mask & 0b0010) != 0 {
            self.paint_cell_rect(buf, (half_x, layout.y_t, layout.x_r, half_y), fg, faint);
        }

        if (mask & 0b0100) != 0 {
            self.paint_cell_rect(buf, (layout.x_l, half_y, half_x, layout.y_b), fg, faint);
        }

        if (mask & 0b1000) != 0 {
            self.paint_cell_rect(buf, (half_x, half_y, layout.x_r, layout.y_b), fg, faint);
        }
    }

    fn paint_sextants(
        &self,
        buf: &mut [RGBA8],
        layout: CellLayout,
        fg: RGBA8,
        faint: bool,
        mask: u8,
    ) {
        let x_mid = split(layout.x_l, layout.x_r, 1, 2);
        let y_1 = split(layout.y_t, layout.y_b, 1, 3);
        let y_2 = split(layout.y_t, layout.y_b, 2, 3);

        if (mask & 0b000001) != 0 {
            self.paint_cell_rect(buf, (layout.x_l, layout.y_t, x_mid, y_1), fg, faint);
        }

        if (mask & 0b000010) != 0 {
            self.paint_cell_rect(buf, (x_mid, layout.y_t, layout.x_r, y_1), fg, faint);
        }

        if (mask & 0b000100) != 0 {
            self.paint_cell_rect(buf, (layout.x_l, y_1, x_mid, y_2), fg, faint);
        }

        if (mask & 0b001000) != 0 {
            self.paint_cell_rect(buf, (x_mid, y_1, layout.x_r, y_2), fg, faint);
        }

        if (mask & 0b010000) != 0 {
            self.paint_cell_rect(buf, (layout.x_l, y_2, x_mid, layout.y_b), fg, faint);
        }

        if (mask & 0b100000) != 0 {
            self.paint_cell_rect(buf, (x_mid, y_2, layout.x_r, layout.y_b), fg, faint);
        }
    }

    fn paint_cell_rect(
        &self,
        buf: &mut [RGBA8],
        rect: (usize, usize, usize, usize),
        fg: RGBA8,
        faint: bool,
    ) {
        self.paint_cell_rect_alpha(buf, rect, fg, if faint { 127 } else { 255 });
    }

    fn paint_cell_rect_alpha(
        &self,
        buf: &mut [RGBA8],
        (x_l, y_t, x_r, y_b): (usize, usize, usize, usize),
        fg: RGBA8,
        ratio: u8,
    ) {
        if x_r <= x_l || y_b <= y_t {
            return;
        }

        let x_l = x_l.min(self.pixel_width);
        let x_r = x_r.min(self.pixel_width);
        let y_t = y_t.min(self.pixel_height);
        let y_b = y_b.min(self.pixel_height);

        for y in y_t..y_b {
            for x in x_l..x_r {
                let idx = y * self.pixel_width + x;
                let bg = buf[idx];

                buf[idx] = blend_straight_alpha(fg, bg, ratio);
            }
        }
    }
}

fn split(start: usize, end: usize, numerator: usize, denominator: usize) -> usize {
    start + ((end - start) * numerator + denominator / 2) / denominator
}

pub(super) fn point_in_triangle(p: (f64, f64), points: [(f64, f64); 3]) -> bool {
    let d1 = edge_sign(p, points[0], points[1]);
    let d2 = edge_sign(p, points[1], points[2]);
    let d3 = edge_sign(p, points[2], points[0]);
    let has_neg = d1 < 0.0 || d2 < 0.0 || d3 < 0.0;
    let has_pos = d1 > 0.0 || d2 > 0.0 || d3 > 0.0;

    !(has_neg && has_pos)
}

fn edge_sign((px, py): (f64, f64), (ax, ay): (f64, f64), (bx, by): (f64, f64)) -> f64 {
    (px - bx) * (ay - by) - (ax - bx) * (py - by)
}

pub(super) fn distance_to_segment(
    (px, py): (f64, f64),
    (ax, ay): (f64, f64),
    (bx, by): (f64, f64),
) -> f64 {
    let dx = bx - ax;
    let dy = by - ay;
    let len_sq = dx * dx + dy * dy;

    if len_sq == 0.0 {
        return ((px - ax).powi(2) + (py - ay).powi(2)).sqrt();
    }

    let t = (((px - ax) * dx + (py - ay) * dy) / len_sq).clamp(0.0, 1.0);
    let x = ax + t * dx;
    let y = ay + t * dy;

    ((px - x).powi(2) + (py - y).powi(2)).sqrt()
}

pub(super) fn ellipse_contains(dx: f64, dy: f64, rx: f64, ry: f64) -> bool {
    if rx <= 0.0 || ry <= 0.0 {
        return false;
    }

    (dx / rx).powi(2) + (dy / ry).powi(2) <= 1.0
}

fn sextant_mask(cp: u32) -> Option<u8> {
    if !(0x1FB00..=0x1FB3B).contains(&cp) {
        return None;
    }

    let offset = (cp - 0x1FB00) as u8;
    let shift = match offset / 20 {
        0 => 1,
        1 => 2,
        _ => 3,
    };

    Some(offset + shift)
}
