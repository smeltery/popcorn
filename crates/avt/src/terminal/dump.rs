use super::{as_u16, BufferType, CursorKeysMode, SavedCtx, Terminal};
use crate::buffer::Buffer;
use crate::cell::{Cell, Occupancy};
use crate::charset::Charset;
use crate::parser::{AnsiMode, AnsiModes, CtcOp, DecMode, DecModes, Function, SgrOp, SgrOps};
use crate::pen::{Intensity, Pen};
use crate::tabs::Tabs;
use std::cmp::Ordering;

impl Terminal {
    pub fn dump(&self) -> Vec<Function> {
        let (primary_ctx, alternate_ctx): (&SavedCtx, &SavedCtx) = match self.active_buffer_type {
            BufferType::Primary => (&self.saved_ctx, &self.alternate_saved_ctx),
            BufferType::Alternate => (&self.alternate_saved_ctx, &self.saved_ctx),
        };

        let mut funs = Vec::new();
        dump_buffer(self.primary_buffer(), &mut funs);
        self.dump_tabs(&mut funs);
        self.dump_saved_context(primary_ctx, &mut funs);

        funs.push(to_sgr(&Pen::default()));

        if self.active_buffer_type == BufferType::Alternate || !alternate_ctx.is_default() {
            funs.push(Function::Decset(DecModes::one(DecMode::AltScreenBuffer)));
        }

        if self.active_buffer_type == BufferType::Alternate {
            funs.push(Function::Cup(1, 1));
            dump_buffer(self.alternate_buffer(), &mut funs);
        }

        self.dump_saved_context(alternate_ctx, &mut funs);

        if self.active_buffer_type == BufferType::Primary && !alternate_ctx.is_default() {
            funs.push(Function::Decrst(DecModes::one(DecMode::AltScreenBuffer)));
        }

        self.dump_runtime_modes(&mut funs);
        self.dump_cursor_position(&mut funs);
        self.dump_cursor_overflow(&mut funs);

        funs.push(to_sgr(&self.pen));

        if !self.cursor.visible {
            funs.push(Function::Decrst(DecModes::one(DecMode::TextCursorEnable)));
        }

        self.dump_print_modes(&mut funs);

        funs
    }

    fn dump_tabs(&self, funs: &mut Vec<Function>) {
        if self.tabs == Tabs::new(self.cols) {
            return;
        }

        funs.push(Function::Ctc(CtcOp::ClearAll));

        for t in &self.tabs {
            funs.push(Function::Cha(as_u16(t + 1)));
            funs.push(Function::Ctc(CtcOp::Set));
        }
    }

    fn dump_saved_context(&self, ctx: &SavedCtx, funs: &mut Vec<Function>) {
        if ctx.is_default() {
            return;
        }

        if !ctx.auto_wrap_mode {
            funs.push(Function::Decrst(DecModes::one(DecMode::AutoWrap)));
        }

        if ctx.origin_mode {
            funs.push(Function::Decset(DecModes::one(DecMode::Origin)));
        }

        funs.push(Function::Cup(
            as_u16(ctx.cursor_row + 1),
            as_u16(ctx.cursor_col + 1),
        ));
        funs.push(to_sgr(&ctx.pen));
        funs.push(Function::Decsc);

        if !ctx.auto_wrap_mode {
            funs.push(Function::Decset(DecModes::one(DecMode::AutoWrap)));
        }

        if ctx.origin_mode {
            funs.push(Function::Decrst(DecModes::one(DecMode::Origin)));
        }
    }

    fn dump_runtime_modes(&self, funs: &mut Vec<Function>) {
        if self.origin_mode {
            funs.push(Function::Decset(DecModes::one(DecMode::Origin)));
        }

        if self.top_margin > 0 || self.bottom_margin < self.rows - 1 {
            funs.push(Function::Decstbm(
                as_u16(self.top_margin + 1),
                as_u16(self.bottom_margin + 1),
            ));
        }
    }

    fn dump_cursor_position(&self, funs: &mut Vec<Function>) {
        let col = self.cursor.col;
        let mut row = self.cursor.row;

        if !self.origin_mode {
            funs.push(Function::Cup(as_u16(row + 1), as_u16(col + 1)));
            return;
        }

        if row < self.top_margin || row > self.bottom_margin {
            funs.push(Function::Scorc);
            self.dump_relative_cursor_move(col, row, funs);
        } else {
            row -= self.top_margin;
            funs.push(Function::Cup(as_u16(row + 1), as_u16(col + 1)));
        }
    }

    fn dump_relative_cursor_move(&self, col: usize, row: usize, funs: &mut Vec<Function>) {
        match col.cmp(&self.saved_ctx.cursor_col) {
            Ordering::Less => {
                let n = self.saved_ctx.cursor_col - col;
                funs.push(Function::Cub(as_u16(n)));
            }
            Ordering::Greater => {
                let n = col - self.saved_ctx.cursor_col;
                funs.push(Function::Cuf(as_u16(n)));
            }
            Ordering::Equal => (),
        }

        match row.cmp(&self.saved_ctx.cursor_row) {
            Ordering::Less => {
                let n = self.saved_ctx.cursor_row - row;
                funs.push(Function::Cuu(as_u16(n)));
            }
            Ordering::Greater => {
                let n = row - self.saved_ctx.cursor_row;
                funs.push(Function::Cud(as_u16(n)));
            }
            Ordering::Equal => (),
        }
    }

    fn dump_cursor_overflow(&self, funs: &mut Vec<Function>) {
        if self.cursor.col < self.cols {
            return;
        }

        let last_cell = self.buffer[(self.cols - 1, self.cursor.row)];
        let occupancy = last_cell.occupancy();

        if occupancy == Occupancy::Single {
            funs.push(to_sgr(last_cell.pen()));
            funs.push(Function::Print(last_cell.char()));
        } else if occupancy == Occupancy::WideTail {
            let prev_cell = self.buffer[(self.cols - 2, self.cursor.row)];

            funs.push(Function::Cub(1));
            funs.push(to_sgr(prev_cell.pen()));
            funs.push(Function::Print(prev_cell.char()));
        }
    }

    fn dump_print_modes(&self, funs: &mut Vec<Function>) {
        if self.charsets[0] == Charset::Drawing {
            funs.push(Function::Gzd4(Charset::Drawing));
        }

        if self.charsets[1] == Charset::Drawing {
            funs.push(Function::G1d4(Charset::Drawing));
        }

        if self.active_charset == 1 {
            funs.push(Function::So);
        }

        if self.insert_mode {
            funs.push(Function::Sm(AnsiModes::one(AnsiMode::Insert)));
        }

        if !self.auto_wrap_mode {
            funs.push(Function::Decrst(DecModes::one(DecMode::AutoWrap)));
        }

        if self.new_line_mode {
            funs.push(Function::Sm(AnsiModes::one(AnsiMode::NewLine)));
        }

        if self.cursor_keys_mode == CursorKeysMode::Application {
            funs.push(Function::Decset(DecModes::one(DecMode::CursorKeys)));
        }
    }
}

fn dump_buffer(buffer: &Buffer, funs: &mut Vec<Function>) {
    let mut cutoff = 0;
    let mut wrapped = false;

    for (i, line) in buffer.view().enumerate() {
        if wrapped || line.wrapped || !line.is_blank() {
            cutoff = i + 1;
        }

        wrapped = line.wrapped;
    }

    let last = buffer.rows - 1;
    let mut pen = Pen::default();

    for (i, line) in buffer.view().take(cutoff).enumerate() {
        for cells in line.chunks(|c1, c2| c1.pen() != c2.pen()) {
            if cells[0].pen() != &pen {
                if let Some(sgr) = to_sgr_diff(&pen, cells[0].pen()) {
                    funs.push(sgr);
                }

                pen = *cells[0].pen();
            }

            dump_cells(&cells, funs);
        }

        if i < last && !line.wrapped {
            funs.push(Function::Cr);
            funs.push(Function::Lf);
        }
    }
}

pub(super) fn to_sgr_diff(from: &Pen, to: &Pen) -> Option<Function> {
    if from == to {
        return None;
    }

    let full = to_sgr_ops(to);
    let diff = to_sgr_diff_ops(from, to);
    let ops = if diff.len() <= full.len() { diff } else { full };

    Some(Function::Sgr(ops))
}

fn to_sgr_diff_ops(from: &Pen, to: &Pen) -> SgrOps {
    let mut ops = SgrOps::new();

    if from.intensity != to.intensity {
        match to.intensity {
            Intensity::Normal => ops.push(SgrOp::ResetIntensity),
            Intensity::Bold => ops.push(SgrOp::SetBoldIntensity),
            Intensity::Faint => ops.push(SgrOp::SetFaintIntensity),
        }
    }

    if from.foreground() != to.foreground() {
        match to.foreground() {
            Some(color) => ops.push(SgrOp::SetForegroundColor(color)),
            None => ops.push(SgrOp::ResetForegroundColor),
        }
    }

    if from.background() != to.background() {
        match to.background() {
            Some(color) => ops.push(SgrOp::SetBackgroundColor(color)),
            None => ops.push(SgrOp::ResetBackgroundColor),
        }
    }

    push_attr_diff(
        &mut ops,
        from.is_italic(),
        to.is_italic(),
        SgrOp::SetItalic,
        SgrOp::ResetItalic,
    );
    push_attr_diff(
        &mut ops,
        from.is_underline(),
        to.is_underline(),
        SgrOp::SetUnderline,
        SgrOp::ResetUnderline,
    );
    push_attr_diff(
        &mut ops,
        from.is_blink(),
        to.is_blink(),
        SgrOp::SetBlink,
        SgrOp::ResetBlink,
    );
    push_attr_diff(
        &mut ops,
        from.is_inverse(),
        to.is_inverse(),
        SgrOp::SetInverse,
        SgrOp::ResetInverse,
    );
    push_attr_diff(
        &mut ops,
        from.is_strikethrough(),
        to.is_strikethrough(),
        SgrOp::SetStrikethrough,
        SgrOp::ResetStrikethrough,
    );

    ops
}

fn push_attr_diff(ops: &mut SgrOps, from: bool, to: bool, set: SgrOp, reset: SgrOp) {
    if from != to {
        ops.push(if to { set } else { reset });
    }
}

fn dump_cells(cells: &[Cell], funs: &mut Vec<Function>) {
    let mut i = 0;

    while i < cells.len() {
        let ch = cells[i].char();
        let mut run_len = 1;

        while i + run_len < cells.len() && cells[i + run_len].char() == ch {
            run_len += 1;
        }

        if run_len > 5 {
            funs.push(Function::Print(ch));
            funs.push(Function::Rep(as_u16(run_len - 1)));
        } else {
            for _ in 0..run_len {
                funs.push(Function::Print(ch));
            }
        }

        i += run_len;
    }
}

fn to_sgr(pen: &Pen) -> Function {
    Function::Sgr(to_sgr_ops(pen))
}

fn to_sgr_ops(pen: &Pen) -> SgrOps {
    let mut ops = SgrOps::new();
    ops.push(SgrOp::Reset);

    if let Some(color) = pen.foreground() {
        ops.push(SgrOp::SetForegroundColor(color));
    }

    if let Some(color) = pen.background() {
        ops.push(SgrOp::SetBackgroundColor(color));
    }

    match pen.intensity {
        Intensity::Normal => {}
        Intensity::Bold => ops.push(SgrOp::SetBoldIntensity),
        Intensity::Faint => ops.push(SgrOp::SetFaintIntensity),
    }

    if pen.is_italic() {
        ops.push(SgrOp::SetItalic);
    }

    if pen.is_underline() {
        ops.push(SgrOp::SetUnderline);
    }

    if pen.is_blink() {
        ops.push(SgrOp::SetBlink);
    }

    if pen.is_inverse() {
        ops.push(SgrOp::SetInverse);
    }

    if pen.is_strikethrough() {
        ops.push(SgrOp::SetStrikethrough);
    }

    ops
}
