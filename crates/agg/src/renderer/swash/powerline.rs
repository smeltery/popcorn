use rgb::RGBA8;

use crate::renderer::TextAttrs;

use super::mosaic::{distance_to_segment, ellipse_contains, point_in_triangle};
use super::{blend_straight_alpha, CellLayout, SwashRenderer};

const POWERLINE_NUDGE: f64 = 0.02;
const POWERLINE_SAMPLES: usize = 4;

impl SwashRenderer {
    pub(super) fn paint_powerline_symbol(
        &self,
        buf: &mut [RGBA8],
        ch: char,
        layout: CellLayout,
        attrs: &TextAttrs,
        fg: RGBA8,
    ) -> bool {
        match ch as u32 {
            // powerline right full triangle
            0xE0B0 => self.paint_powerline_filled_triangle(
                buf,
                layout,
                fg,
                attrs.faint,
                [(0.0, 0.0), (1.0, 0.5), (0.0, 1.0)],
            ),

            // powerline right bracket
            0xE0B1 => self.paint_powerline_stroke_segments(
                buf,
                layout,
                fg,
                attrs.faint,
                [((0.0, 0.0), (1.0, 0.5)), ((1.0, 0.5), (0.0, 1.0))],
            ),

            // powerline left full triangle
            0xE0B2 => self.paint_powerline_filled_triangle(
                buf,
                layout,
                fg,
                attrs.faint,
                [(1.0, 0.0), (0.0, 0.5), (1.0, 1.0)],
            ),

            // powerline left bracket
            0xE0B3 => self.paint_powerline_stroke_segments(
                buf,
                layout,
                fg,
                attrs.faint,
                [((1.0, 0.0), (0.0, 0.5)), ((0.0, 0.5), (1.0, 1.0))],
            ),

            // nf-ple-right_half_circle_thick
            0xE0B4 => self.paint_powerline_filled_cap(buf, layout, fg, attrs.faint, true),

            // nf-ple-right_half_circle_thin
            0xE0B5 => self.paint_powerline_stroked_cap(buf, layout, fg, attrs.faint, true),

            // nf-ple-left_half_circle_thick
            0xE0B6 => self.paint_powerline_filled_cap(buf, layout, fg, attrs.faint, false),

            // nf-ple-left_half_circle_thin
            0xE0B7 => self.paint_powerline_stroked_cap(buf, layout, fg, attrs.faint, false),

            // nf-ple-lower_left_triangle
            0xE0B8 => self.paint_powerline_filled_triangle(
                buf,
                layout,
                fg,
                attrs.faint,
                [(0.0, 1.0), (0.0, 0.0), (1.0, 1.0)],
            ),

            // nf-ple-backslash_separator + redundant
            0xE0B9 | 0xE0BF => self.paint_powerline_stroke_segments(
                buf,
                layout,
                fg,
                attrs.faint,
                [((0.0, 0.0), (1.0, 1.0))],
            ),

            // nf-ple-lower_right_triangle
            0xE0BA => self.paint_powerline_filled_triangle(
                buf,
                layout,
                fg,
                attrs.faint,
                [(1.0, 1.0), (1.0, 0.0), (0.0, 1.0)],
            ),

            // nf-ple-forwardslash_separator + redundant
            0xE0BB | 0xE0BD => self.paint_powerline_stroke_segments(
                buf,
                layout,
                fg,
                attrs.faint,
                [((0.0, 1.0), (1.0, 0.0))],
            ),

            // nf-ple-upper_left_triangle
            0xE0BC => self.paint_powerline_filled_triangle(
                buf,
                layout,
                fg,
                attrs.faint,
                [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0)],
            ),

            // nf-ple-upper_right_triangle
            0xE0BE => self.paint_powerline_filled_triangle(
                buf,
                layout,
                fg,
                attrs.faint,
                [(1.0, 0.0), (1.0, 1.0), (0.0, 0.0)],
            ),

            _ => return false,
        }

        true
    }

    fn paint_powerline_filled_triangle(
        &self,
        buf: &mut [RGBA8],
        layout: CellLayout,
        fg: RGBA8,
        faint: bool,
        points: [(f64, f64); 3],
    ) {
        self.paint_powerline_samples(buf, layout, fg, faint, |x, y, _, _| {
            point_in_triangle((x, y), points)
        });
    }

    fn paint_powerline_stroke_segments<const N: usize>(
        &self,
        buf: &mut [RGBA8],
        layout: CellLayout,
        fg: RGBA8,
        faint: bool,
        segments: [((f64, f64), (f64, f64)); N],
    ) {
        let (draw_l, draw_w, _, cell_h) = self.powerline_bounds(layout);
        let stroke_radius = self.powerline_stroke_width() / 2.0;

        self.paint_powerline_samples(buf, layout, fg, faint, |_, _, px, py| {
            segments.iter().any(|&(a, b)| {
                // Stroke widths are measured in pixels, so diagonal and curved
                // Powerline strokes match box-drawing line thickness.
                let a = (draw_l + a.0 * draw_w, layout.y_t as f64 + a.1 * cell_h);
                let b = (draw_l + b.0 * draw_w, layout.y_t as f64 + b.1 * cell_h);

                distance_to_segment((px, py), a, b) <= stroke_radius
            })
        });
    }

    fn paint_powerline_filled_cap(
        &self,
        buf: &mut [RGBA8],
        layout: CellLayout,
        fg: RGBA8,
        faint: bool,
        right: bool,
    ) {
        self.paint_powerline_samples(buf, layout, fg, faint, |x, y, _, _| {
            // Half-disk from an ellipse centered on the left or right cell edge.
            let dx = if right { x } else { 1.0 - x };
            let dy = (y - 0.5) / 0.5;

            dx >= 0.0 && dx * dx + dy * dy <= 1.0
        });
    }

    fn paint_powerline_stroked_cap(
        &self,
        buf: &mut [RGBA8],
        layout: CellLayout,
        fg: RGBA8,
        faint: bool,
        right: bool,
    ) {
        let (draw_l, draw_w, _, cell_h) = self.powerline_bounds(layout);
        let stroke_width = self.powerline_stroke_width();
        let outer_rx = draw_w;
        let outer_ry = cell_h / 2.0;
        // The stroked cap is the outer half-ellipse minus a smaller inner one.
        let inner_rx = (outer_rx - stroke_width).max(0.0);
        let inner_ry = (outer_ry - stroke_width).max(0.0);
        let cx = if right { draw_l } else { draw_l + draw_w };
        let cy = layout.y_t as f64 + outer_ry;

        self.paint_powerline_samples(buf, layout, fg, faint, |_, _, px, py| {
            let dx = (px - cx).abs();
            let dy = (py - cy).abs();
            let inside_outer = ellipse_contains(dx, dy, outer_rx, outer_ry);
            let inside_inner = ellipse_contains(dx, dy, inner_rx, inner_ry);

            inside_outer && !inside_inner
        });
    }

    fn paint_powerline_samples(
        &self,
        buf: &mut [RGBA8],
        layout: CellLayout,
        fg: RGBA8,
        faint: bool,
        covers: impl Fn(f64, f64, f64, f64) -> bool,
    ) {
        let (draw_l, draw_w, cell_w, cell_h) = self.powerline_bounds(layout);

        if cell_w <= 0.0 || cell_h <= 0.0 {
            return;
        }

        let x_l = draw_l.floor().max(0.0) as usize;
        let x_r = (draw_l + draw_w).ceil().min(self.pixel_width as f64) as usize;
        let y_t = layout.y_t.min(self.pixel_height);
        let y_b = layout.y_b.min(self.pixel_height);
        let samples = POWERLINE_SAMPLES * POWERLINE_SAMPLES;
        let max_alpha = if faint { 127 } else { 255 };

        for y in y_t..y_b {
            for x in x_l..x_r {
                let mut coverage = 0;

                for sy in 0..POWERLINE_SAMPLES {
                    for sx in 0..POWERLINE_SAMPLES {
                        // Small fixed supersampling gives stable anti-aliased edges
                        // without pulling in another rasterizer.
                        let px = x as f64 + (sx as f64 + 0.5) / POWERLINE_SAMPLES as f64;
                        let py = y as f64 + (sy as f64 + 0.5) / POWERLINE_SAMPLES as f64;
                        let nx = (px - draw_l) / draw_w;
                        let ny = (py - layout.y_t as f64) / cell_h;

                        if covers(nx, ny, px, py) {
                            coverage += 1;
                        }
                    }
                }

                if coverage == 0 {
                    continue;
                }

                let ratio = ((coverage * max_alpha + samples / 2) / samples) as u8;
                let idx = y * self.pixel_width + x;
                buf[idx] = blend_straight_alpha(fg, buf[idx], ratio);
            }
        }
    }

    fn powerline_bounds(&self, layout: CellLayout) -> (f64, f64, f64, f64) {
        let cell_w = layout.x_r.saturating_sub(layout.x_l) as f64;
        let cell_h = layout.y_b.saturating_sub(layout.y_t) as f64;
        let nudge = cell_w * POWERLINE_NUDGE;
        let draw_l = layout.x_l as f64 - nudge;
        let draw_w = cell_w + nudge * 2.0;

        (draw_l, draw_w, cell_w, cell_h)
    }

    fn powerline_stroke_width(&self) -> f64 {
        self.box_thickness() as f64
    }
}
