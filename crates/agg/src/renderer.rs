mod resvg;
mod swash;

use imgref::ImgVec;
use rgb::{RGB8, RGBA8};

use crate::terminal::Snapshot;
use crate::theme::Theme;

pub trait Renderer {
    fn render(&mut self, snapshot: &Snapshot) -> ImgVec<RGBA8>;
    fn pixel_size(&self) -> (usize, usize);
}

pub struct Settings {
    pub terminal_size: (usize, usize),
    pub font_db: fontdb::Database,
    pub font_families: Vec<String>,
    pub text_family: String,
    pub font_aa_levels: u16,
    pub font_size: usize,
    pub line_height: f64,
    pub theme: Theme,
    pub bold_is_bright: bool,
    pub hinting: bool,
}

pub fn resvg<'a>(settings: Settings) -> resvg::ResvgRenderer<'a> {
    resvg::ResvgRenderer::new(settings)
}

pub fn swash(settings: Settings) -> swash::SwashRenderer {
    swash::SwashRenderer::new(settings)
}

#[derive(Clone, Copy)]
struct TextAttrs {
    foreground: Option<popcorn_terminal::Color>,
    background: Option<popcorn_terminal::Color>,
    bold: bool,
    faint: bool,
    italic: bool,
    underline: bool,
}

fn text_attrs(
    pen: &popcorn_terminal::Pen,
    cursor: &Option<(usize, usize)>,
    col: usize,
    row: usize,
    theme: &Theme,
    bold_is_bright: bool,
) -> TextAttrs {
    let mut foreground = pen.foreground();
    let mut background = pen.background();
    let inverse = cursor == &Some((col, row));

    if bold_is_bright && pen.is_bold() {
        if let Some(popcorn_terminal::Color::Indexed(n)) = foreground {
            if n < 8 {
                foreground = Some(popcorn_terminal::Color::Indexed(n + 8));
            }
        }
    }

    if pen.is_inverse() ^ inverse {
        let fg = background.unwrap_or(popcorn_terminal::Color::RGB(theme.background));
        let bg = foreground.unwrap_or(popcorn_terminal::Color::RGB(theme.foreground));
        foreground = Some(fg);
        background = Some(bg);
    }

    TextAttrs {
        foreground,
        background,
        bold: pen.is_bold(),
        faint: pen.is_faint(),
        italic: pen.is_italic(),
        underline: pen.is_underline(),
    }
}

fn color_to_rgb(c: &popcorn_terminal::Color, theme: &Theme) -> RGB8 {
    match c {
        popcorn_terminal::Color::RGB(c) => *c,
        popcorn_terminal::Color::Indexed(c) => theme.color(*c),
    }
}

#[cfg(test)]
mod tests;
