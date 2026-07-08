use std::collections::hash_map::DefaultHasher;
use std::collections::{HashMap, HashSet};
use std::hash::{Hash, Hasher};

use imgref::ImgVec;
use log::debug;
use rgb::RGBA8;
use swash::scale::image::{Content, Image};
use swash::scale::{Render, ScaleContext, Source, StrikeWith};
use swash::FontRef;

use crate::renderer::{color_to_rgb, text_attrs, Renderer, Settings, TextAttrs};
use crate::terminal::Snapshot;
use crate::theme::Theme;

mod mosaic;
mod powerline;

type CharVariant = (char, bool, bool);
type FontFace = (String, bool, bool);

const GLYPH_SOURCES: &[Source] = &[
    Source::ColorOutline(0),
    Source::ColorBitmap(StrikeWith::BestFit),
    Source::Outline,
    Source::Bitmap(StrikeWith::BestFit),
];

#[derive(Clone, Copy)]
struct CellLayout {
    x_l: usize,
    x_r: usize,
    y_t: usize,
    y_b: usize,
    baseline: i32,
    underline_y: usize,
}

struct RenderCell {
    ch: char,
    layout: CellLayout,
    attrs: TextAttrs,
    fg: RGBA8,
}

pub struct SwashRenderer {
    font_families: Vec<String>,
    theme: Theme,
    pixel_width: usize,
    pixel_height: usize,
    font_aa_levels: u16,
    font_size: usize,
    col_width: f64,
    row_height: f64,
    underline_offset: f64,
    underline_thickness: f64,
    font_db: fontdb::Database,
    scale_context: ScaleContext,
    glyph_cache: HashMap<CharVariant, Option<Image>>,
    font_id_cache: HashMap<FontFace, Option<fontdb::ID>>,
    bold_is_bright: bool,
    hinting: bool,
}

fn get_font_id<T: AsRef<str> + std::fmt::Debug>(
    db: &fontdb::Database,
    families: &[T],
    weight: fontdb::Weight,
    style: fontdb::Style,
) -> Option<fontdb::ID> {
    debug!(
        "looking up font for families={:?}, weight={}, style={:?}",
        families, weight.0, style
    );

    let families: Vec<fontdb::Family> = families
        .iter()
        .map(|name| fontdb::Family::Name(name.as_ref()))
        .collect();

    let query = fontdb::Query {
        families: &families,
        weight,
        stretch: fontdb::Stretch::Normal,
        style,
    };

    let font_id = db.query(&query)?;

    debug!("found font with id={:?}", font_id);

    Some(font_id)
}

fn font_id_key(font_id: fontdb::ID) -> [u64; 2] {
    // fontdb::ID has no public raw representation. Swash only needs this
    // key to be stable within our ScaleContext, and DefaultHasher::new()
    // is deterministic (unlike RandomState). The second slot of the key
    // is swash's sub-font discriminator (e.g. variation instance), which
    // we don't use, so we leave it at 0.
    let mut hasher = DefaultHasher::new();
    font_id.hash(&mut hasher);
    [hasher.finish(), 0]
}

fn col_width(db: &fontdb::Database, family: &str, font_size: usize) -> Option<f64> {
    let font_id = get_font_id(db, &[family], fontdb::Weight::NORMAL, fontdb::Style::Normal)?;

    db.with_face_data(font_id, |font_data, face_index| {
        let font = FontRef::from_index(font_data, face_index as usize)?;
        let glyph_id = font.charmap().map('/');
        let metrics = font.glyph_metrics(&[]).scale(font_size as f32);

        Some(metrics.advance_width(glyph_id) as f64)
    })?
}

fn underline_metrics(db: &fontdb::Database, family: &str, font_size: usize) -> Option<(f64, f64)> {
    let font_id = get_font_id(db, &[family], fontdb::Weight::NORMAL, fontdb::Style::Normal)?;

    db.with_face_data(font_id, |font_data, face_index| {
        let font = FontRef::from_index(font_data, face_index as usize)?;
        let metrics = font.metrics(&[]).scale(font_size as f32);

        Some((metrics.underline_offset as f64, metrics.stroke_size as f64))
    })?
}

fn glyph_image_is_visible(img: &Image) -> bool {
    img.placement.width > 0 && img.placement.height > 0 && !img.data.is_empty()
}

fn font_weight(bold: bool) -> fontdb::Weight {
    if bold {
        fontdb::Weight::BOLD
    } else {
        fontdb::Weight::NORMAL
    }
}

fn font_style(italic: bool) -> fontdb::Style {
    if italic {
        fontdb::Style::Italic
    } else {
        fontdb::Style::Normal
    }
}

impl SwashRenderer {
    pub fn new(settings: Settings) -> Self {
        let col_width = col_width(&settings.font_db, &settings.text_family, settings.font_size)
            .expect("text_family is guaranteed to resolve by fonts::init");

        let (underline_offset, underline_thickness) =
            underline_metrics(&settings.font_db, &settings.text_family, settings.font_size)
                .expect("text_family is guaranteed to resolve by fonts::init");

        let (cols, rows) = settings.terminal_size;
        let row_height = (settings.font_size as f64) * settings.line_height;

        Self {
            font_db: settings.font_db,
            font_families: settings.font_families,
            theme: settings.theme,
            pixel_width: ((cols + 2) as f64 * col_width).round() as usize,
            pixel_height: ((rows + 1) as f64 * row_height).round() as usize,
            font_aa_levels: settings.font_aa_levels,
            font_size: settings.font_size,
            col_width,
            row_height,
            underline_offset,
            underline_thickness,
            scale_context: ScaleContext::new(),
            font_id_cache: HashMap::new(),
            glyph_cache: HashMap::new(),
            bold_is_bright: settings.bold_is_bright,
            hinting: settings.hinting,
        }
    }

    fn get_font_id(&mut self, name: &str, bold: bool, italic: bool) -> &Option<fontdb::ID> {
        self.font_id_cache
            .entry((name.to_owned(), bold, italic))
            .or_insert_with(|| {
                get_font_id(
                    &self.font_db,
                    &[name],
                    font_weight(bold),
                    font_style(italic),
                )
            })
    }

    fn ensure_glyph(&mut self, ch: char, bold: bool, italic: bool) {
        let key = (ch, bold, italic);

        if self.glyph_cache.contains_key(&key) {
            return;
        }

        let mut tried_font_ids = HashSet::new();

        if let Some(glyph) = self.rasterize_family_glyph(ch, bold, italic, &mut tried_font_ids) {
            self.glyph_cache.insert(key, Some(glyph));
            return;
        }

        if bold || italic {
            if let Some(glyph) = self.rasterize_family_glyph(ch, false, false, &mut tried_font_ids)
            {
                self.glyph_cache.insert(key, Some(glyph));
                return;
            }
        }

        if let Some(glyph) = self.rasterize_fallback_glyph(ch, bold, italic, &tried_font_ids) {
            self.glyph_cache.insert(key, Some(glyph));
            return;
        }

        if bold || italic {
            if let Some(glyph) = self.rasterize_fallback_glyph(ch, false, false, &tried_font_ids) {
                self.glyph_cache.insert(key, Some(glyph));
                return;
            }
        }

        self.glyph_cache.insert(key, None);
    }

    fn get_glyph(&self, ch: char, bold: bool, italic: bool) -> &Option<Image> {
        self.glyph_cache
            .get(&(ch, bold, italic))
            .expect("caller must invoke ensure_glyph first")
    }

    fn rasterize_family_glyph(
        &mut self,
        ch: char,
        bold: bool,
        italic: bool,
        tried_font_ids: &mut HashSet<fontdb::ID>,
    ) -> Option<Image> {
        let families = self.font_families.clone();

        for name in &families {
            let Some(font_id) = *self.get_font_id(name, bold, italic) else {
                continue;
            };

            tried_font_ids.insert(font_id);

            if let Some(glyph) = self.rasterize_font_glyph(font_id, ch) {
                return Some(glyph);
            }
        }

        None
    }

    fn rasterize_fallback_glyph(
        &mut self,
        ch: char,
        bold: bool,
        italic: bool,
        tried_font_ids: &HashSet<fontdb::ID>,
    ) -> Option<Image> {
        let weight = font_weight(bold);
        let style = font_style(italic);

        // Match resvg/usvg behavior: if configured families miss, try any
        // loaded face so system fonts and --font-dir fonts can cover unlisted scripts.
        let fallback_font_ids: Vec<_> = self
            .font_db
            .faces()
            .filter(|face| {
                !tried_font_ids.contains(&face.id) && face.weight == weight && face.style == style
            })
            .map(|face| face.id)
            .collect();

        for font_id in fallback_font_ids {
            if let Some(glyph) = self.rasterize_font_glyph(font_id, ch) {
                return Some(glyph);
            }
        }

        None
    }

    fn rasterize_font_glyph(&mut self, font_id: fontdb::ID, ch: char) -> Option<Image> {
        let font_size = self.font_size as f32;
        let hinting = self.hinting;
        let scale_context = &mut self.scale_context;

        self.font_db
            .with_face_data(font_id, |font_data, face_index| {
                let font = FontRef::from_index(font_data, face_index as usize)?;
                let glyph_id = font.charmap().map(ch);

                if glyph_id == 0 {
                    return None;
                }

                let mut scaler = scale_context
                    .builder_with_id(font, font_id_key(font_id))
                    .size(font_size)
                    .hint(hinting)
                    .build();

                // Swash returns an empty image when a mapped glyph is in a
                // table it can't decompose, most notably COLRv1. Drop that
                // result so the family fallback loop can try the next font.
                Render::new(GLYPH_SOURCES)
                    .render(&mut scaler, glyph_id)
                    .filter(glyph_image_is_visible)
            })?
    }

    fn new_frame(&self) -> Vec<RGBA8> {
        vec![self.theme.background.with_alpha(255); self.pixel_width * self.pixel_height]
    }

    fn cell_layout(
        &self,
        margin_l: f64,
        margin_t: usize,
        row: usize,
        col: usize,
        width: usize,
    ) -> CellLayout {
        let baseline =
            margin_t as f64 + self.font_size as f64 + (row as f64 * self.row_height).round();

        CellLayout {
            x_l: (margin_l + col as f64 * self.col_width).round() as usize,
            x_r: (margin_l + (col + width) as f64 * self.col_width).round() as usize,
            y_t: margin_t + (row as f64 * self.row_height).round() as usize,
            y_b: margin_t + ((row + 1) as f64 * self.row_height).round() as usize,
            baseline: baseline as i32,
            underline_y: (baseline - self.underline_offset).round() as usize,
        }
    }

    fn foreground(&self, attrs: &TextAttrs) -> RGBA8 {
        color_to_rgb(
            &attrs
                .foreground
                .unwrap_or(popcorn_terminal::Color::RGB(self.theme.foreground)),
            &self.theme,
        )
        .with_alpha(255)
    }

    fn paint_background(&self, buf: &mut [RGBA8], layout: CellLayout, attrs: &TextAttrs) {
        let Some(c) = &attrs.background else {
            return;
        };

        let c = color_to_rgb(c, &self.theme).with_alpha(255);

        for y in layout.y_t..layout.y_b {
            let idx = y * self.pixel_width;
            buf[idx + layout.x_l..idx + layout.x_r].fill(c);
        }
    }

    fn paint_underline(&self, buf: &mut [RGBA8], layout: CellLayout, fg: RGBA8, underline: bool) {
        if !underline {
            return;
        }

        let thickness = (self.underline_thickness.round() as usize).max(1);

        for dy in 0..thickness {
            let y = layout.underline_y + dy;
            let idx = y * self.pixel_width;
            buf[idx + layout.x_l..idx + layout.x_r].fill(fg);
        }
    }

    fn box_thickness(&self) -> usize {
        (self.underline_thickness.ceil() as usize).max(1)
    }

    fn paint_glyph(
        &mut self,
        buf: &mut [RGBA8],
        ch: char,
        layout: CellLayout,
        attrs: &TextAttrs,
        fg: RGBA8,
    ) {
        self.ensure_glyph(ch, attrs.bold, attrs.italic);
        let glyph = self.get_glyph(ch, attrs.bold, attrs.italic);

        let Some(glyph) = glyph.as_ref() else {
            return;
        };

        let placement = glyph.placement;
        let width = placement.width as usize;
        let height = placement.height as usize;
        let y_offset = layout.baseline - placement.top;
        let x_offset = layout.x_l as i32 + placement.left;

        match glyph.content {
            Content::Mask => {
                self.paint_image(buf, width, height, x_offset, y_offset, |bx, by, bg| {
                    let mut ratio =
                        quantize_alpha(glyph.data[by * width + bx], self.font_aa_levels);

                    if attrs.faint {
                        ratio = (ratio as f32 * 0.5) as u8;
                    }

                    blend_straight_alpha(fg, bg, ratio)
                });
            }

            Content::Color => {
                // Swash returns straight RGBA for color bitmap strikes (CBDT/sbix)
                // but premultiplied RGBA for layered color outlines (COLR/CPAL).
                let premultiplied = matches!(glyph.source, Source::ColorOutline(_));

                self.paint_image(buf, width, height, x_offset, y_offset, |bx, by, bg| {
                    let src_idx = (by * width + bx) * 4;

                    let mut src = RGBA8::new(
                        glyph.data[src_idx],
                        glyph.data[src_idx + 1],
                        glyph.data[src_idx + 2],
                        glyph.data[src_idx + 3],
                    );

                    if attrs.faint {
                        src = fade_color(src, premultiplied);
                    }

                    if premultiplied {
                        blend_premultiplied_alpha(src, bg)
                    } else {
                        blend_straight_alpha(src, bg, src.a)
                    }
                });
            }

            Content::SubpixelMask => {
                // We never request subpixel output from swash; Render defaults
                // to Format::Alpha, which produces Content::Mask for outlines.
                unreachable!("swash renderer does not request subpixel glyph masks");
            }
        }
    }

    fn paint_image(
        &self,
        buf: &mut [RGBA8],
        width: usize,
        height: usize,
        x_offset: i32,
        y_offset: i32,
        mut paint: impl FnMut(usize, usize, RGBA8) -> RGBA8,
    ) {
        for by in 0..height {
            let y = y_offset + by as i32;

            if y < 0 || y >= self.pixel_height as i32 {
                continue;
            }

            for bx in 0..width {
                let x = x_offset + bx as i32;

                if x < 0 || x >= self.pixel_width as i32 {
                    continue;
                }

                let idx = (y as usize) * self.pixel_width + (x as usize);
                buf[idx] = paint(bx, by, buf[idx]);
            }
        }
    }
}

fn quantize_alpha(alpha: u8, levels: u16) -> u8 {
    if levels >= crate::FULL_FONT_AA_LEVELS {
        return alpha;
    }

    let steps = levels.max(2) - 1;
    let bucket = ((alpha as u16 * steps + 127) / 255).min(steps);

    ((bucket * 255 + steps / 2) / steps) as u8
}

fn blend_straight_alpha(fg: RGBA8, bg: RGBA8, ratio: u8) -> RGBA8 {
    let ratio = ratio as u16;

    RGBA8::new(
        ((bg.r as u16) * (255 - ratio) / 255) as u8 + ((fg.r as u16) * ratio / 255) as u8,
        ((bg.g as u16) * (255 - ratio) / 255) as u8 + ((fg.g as u16) * ratio / 255) as u8,
        ((bg.b as u16) * (255 - ratio) / 255) as u8 + ((fg.b as u16) * ratio / 255) as u8,
        255,
    )
}

fn blend_premultiplied_alpha(fg: RGBA8, bg: RGBA8) -> RGBA8 {
    let inverse = 255 - fg.a as u16;

    RGBA8::new(
        (fg.r as u16 + (bg.r as u16) * inverse / 255).min(255) as u8,
        (fg.g as u16 + (bg.g as u16) * inverse / 255).min(255) as u8,
        (fg.b as u16 + (bg.b as u16) * inverse / 255).min(255) as u8,
        255,
    )
}

fn fade_color(mut color: RGBA8, premultiplied: bool) -> RGBA8 {
    if premultiplied {
        color.r /= 2;
        color.g /= 2;
        color.b /= 2;
    }

    color.a /= 2;

    color
}

impl Renderer for SwashRenderer {
    fn render(&mut self, snapshot: &Snapshot) -> ImgVec<RGBA8> {
        let mut buf = self.new_frame();
        let margin_l = self.col_width;
        let margin_t = (self.row_height / 2.0).round() as usize;
        let mut cells = Vec::new();

        for (row, line) in snapshot.lines.iter().enumerate() {
            let mut col = 0;

            for cell in line.cells() {
                let ch = cell.char();
                let cell_width = cell.width() as usize;
                let layout = self.cell_layout(margin_l, margin_t, row, col, cell_width);

                let attrs = text_attrs(
                    cell.pen(),
                    &snapshot.cursor,
                    col,
                    row,
                    &self.theme,
                    self.bold_is_bright,
                );

                let fg = self.foreground(&attrs);

                cells.push(RenderCell {
                    ch,
                    layout,
                    attrs,
                    fg,
                });

                col += cell_width;
            }
        }

        for cell in &cells {
            self.paint_background(&mut buf, cell.layout, &cell.attrs);
        }

        for cell in &cells {
            self.paint_underline(&mut buf, cell.layout, cell.fg, cell.attrs.underline);
        }

        for cell in &cells {
            if cell.ch != ' '
                && !self.paint_powerline_symbol(
                    &mut buf,
                    cell.ch,
                    cell.layout,
                    &cell.attrs,
                    cell.fg,
                )
                && !self.paint_mosaic_symbol(&mut buf, cell.ch, cell.layout, &cell.attrs, cell.fg)
            {
                self.paint_glyph(&mut buf, cell.ch, cell.layout, &cell.attrs, cell.fg);
            }
        }

        ImgVec::new(buf, self.pixel_width, self.pixel_height)
    }

    fn pixel_size(&self) -> (usize, usize) {
        (self.pixel_width, self.pixel_height)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn glyph_image_visibility_rejects_empty_images() {
        let mut image = Image::new();

        assert!(!glyph_image_is_visible(&image));

        image.placement.width = 1;
        image.placement.height = 1;
        assert!(!glyph_image_is_visible(&image));

        image.data.push(255);
        assert!(glyph_image_is_visible(&image));
    }

    #[test]
    fn color_bitmap_edges_use_straight_alpha() {
        let bg = RGBA8::new(24, 24, 24, 255);
        let src = RGBA8::new(252, 215, 52, 2);

        assert_eq!(
            blend_straight_alpha(src, bg, src.a),
            RGBA8::new(24, 24, 23, 255)
        );
    }

    #[test]
    fn color_outline_edges_use_premultiplied_alpha() {
        let bg = RGBA8::new(24, 24, 24, 255);
        let src = RGBA8::new(2, 2, 0, 2);

        assert_eq!(
            blend_premultiplied_alpha(src, bg),
            RGBA8::new(25, 25, 23, 255)
        );
    }

    #[test]
    fn faint_color_preserves_alpha_representation() {
        let src = RGBA8::new(100, 80, 60, 40);

        assert_eq!(fade_color(src, false), RGBA8::new(100, 80, 60, 20));
        assert_eq!(fade_color(src, true), RGBA8::new(50, 40, 30, 20));
    }

    #[test]
    fn quantize_alpha_preserves_full_aa() {
        assert_eq!(quantize_alpha(0, crate::FULL_FONT_AA_LEVELS), 0);
        assert_eq!(quantize_alpha(37, crate::FULL_FONT_AA_LEVELS), 37);
        assert_eq!(quantize_alpha(255, crate::FULL_FONT_AA_LEVELS), 255);
    }

    #[test]
    fn quantize_alpha_maps_to_even_levels() {
        assert_eq!(quantize_alpha(0, 4), 0);
        assert_eq!(quantize_alpha(42, 4), 0);
        assert_eq!(quantize_alpha(43, 4), 85);
        assert_eq!(quantize_alpha(128, 4), 170);
        assert_eq!(quantize_alpha(255, 4), 255);
    }

    #[test]
    fn quantize_alpha_treats_two_levels_as_aliased() {
        assert_eq!(quantize_alpha(127, 2), 0);
        assert_eq!(quantize_alpha(128, 2), 255);
    }
}
