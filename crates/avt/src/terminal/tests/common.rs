pub(super) use super::super::dump;
pub(super) use super::super::{BufferType, Occupancy, SavedCtx, Terminal};
pub(super) use crate::charset::Charset;
pub(super) use crate::color::Color;
pub(super) use crate::line::Line;
pub(super) use crate::parser::{
    AnsiMode, AnsiModes, DecMode, DecModes, EdScope, ElScope, Function, SgrOp, SgrOps,
};
pub(super) use crate::pen::Intensity;
pub(super) use crate::pen::Pen;
pub(super) use Function::*;
pub(super) use SgrOp::*;

pub(super) fn feed(term: &mut Terminal, input: &str) {
    for ch in input.chars() {
        let fun = match ch {
            '\n' => Lf,
            '\r' => Cr,
            _ => Print(ch),
        };

        term.execute(fun);
    }
}

pub(super) fn build_term(cols: usize, rows: usize, cx: usize, cy: usize, init: &str) -> Terminal {
    let mut term = Terminal::new((cols, rows), None);
    feed(&mut term, init);
    term.execute(Cup((cy + 1) as u16, (cx + 1) as u16));

    term
}

pub(super) fn text(term: &Terminal) -> String {
    let cursor = term.cursor();

    buffer_text(term.view(), cursor.col, cursor.row)
}

pub(super) fn buffer_text<'a, I: Iterator<Item = &'a Line> + 'a>(
    mut view: I,
    cursor_col: usize,
    cursor_row: usize,
) -> String {
    let mut lines = Vec::new();
    lines.extend(view.by_ref().take(cursor_row).map(|l| l.text()));
    let cursor_line = view.next().unwrap();
    let mut offset = 0;
    let mut line = String::new();

    let mut cells = cursor_line
        .cells()
        .iter()
        .filter(|c| c.occupancy() != Occupancy::WideTail);

    for cell in cells.by_ref() {
        let width = cell.width() as usize;

        if offset + width <= cursor_col {
            line.push(cell.char());
            offset += width;
        } else {
            line.push('|');
            line.push(cell.char());
            offset += width;
            break;
        }
    }

    if offset == cursor_col {
        line.push('|');
    }

    line.extend(cells.map(|c| c.char()));
    lines.push(line);
    lines.extend(view.map(|l| l.text()));

    lines
        .into_iter()
        .map(|line| line.trim_end().to_owned())
        .collect::<Vec<_>>()
        .join("\n")
}

pub(super) fn wrapped(term: &Terminal) -> Vec<bool> {
    term.view().map(|l| l.wrapped).collect()
}

pub(super) fn ansi_modes<const N: usize>(modes: [AnsiMode; N]) -> AnsiModes {
    AnsiModes::from(&modes[..])
}

pub(super) fn dec_modes<const N: usize>(modes: [DecMode; N]) -> DecModes {
    DecModes::from(&modes[..])
}

pub(super) fn sgr(op: SgrOp) -> Function {
    Sgr(SgrOps::from(vec![op]))
}

pub(super) fn pen(f: impl FnOnce(&mut Pen)) -> Pen {
    let mut pen = Pen::default();
    f(&mut pen);
    pen
}
