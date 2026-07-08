mod context;
mod cursor;
mod dirty_lines;
mod dump;
mod execute;
mod lifecycle;
mod position;

use self::context::SavedCtx;
pub use self::cursor::Cursor;
use self::dirty_lines::DirtyLines;
use crate::buffer::{Buffer, EraseMode};
use crate::cell::Occupancy;
use crate::charset::Charset;
use crate::line::Line;
use crate::parser::{
    AnsiMode, AnsiModes, CtcOp, DecMode, DecModes, EdScope, ElScope, SgrOp, SgrOps, TbcScope,
    XtwinopsOp,
};
use crate::pen::{Intensity, Pen};
use crate::tabs::Tabs;

#[derive(Debug)]
pub struct Terminal {
    cols: usize,
    rows: usize,
    buffer: Buffer,
    other_buffer: Buffer,
    active_buffer_type: BufferType,
    scrollback_limit: Option<usize>,
    cursor: Cursor,
    pen: Pen,
    charsets: [Charset; 2],
    active_charset: usize,
    tabs: Tabs,
    insert_mode: bool,
    origin_mode: bool,
    auto_wrap_mode: bool,
    new_line_mode: bool,
    cursor_keys_mode: CursorKeysMode,
    top_margin: usize,
    bottom_margin: usize,
    saved_ctx: SavedCtx,
    alternate_saved_ctx: SavedCtx,
    dirty_lines: DirtyLines,
    xtwinops: bool,
}

#[derive(Debug, Copy, Clone, PartialEq)]
pub enum BufferType {
    Primary,
    Alternate,
}

#[derive(Debug, Copy, Clone, PartialEq)]
pub(crate) enum CursorKeysMode {
    Normal,
    Application,
}

enum PrintResult {
    Printed(usize),
    NeedsRelocation,
}

impl Terminal {
    pub fn new((cols, rows): (usize, usize), scrollback_limit: Option<usize>) -> Self {
        let primary_buffer = Buffer::new(cols, rows, scrollback_limit, None);
        let alternate_buffer = Buffer::new(cols, rows, Some(0), None);
        let dirty_lines = DirtyLines::new(rows);

        Terminal {
            cols,
            rows,
            buffer: primary_buffer,
            other_buffer: alternate_buffer,
            active_buffer_type: BufferType::Primary,
            scrollback_limit,
            tabs: Tabs::new(cols),
            cursor: Cursor::default(),
            pen: Pen::default(),
            charsets: [Charset::Ascii, Charset::Ascii],
            active_charset: 0,
            insert_mode: false,
            origin_mode: false,
            auto_wrap_mode: true,
            new_line_mode: false,
            cursor_keys_mode: CursorKeysMode::Normal,
            top_margin: 0,
            bottom_margin: (rows - 1),
            saved_ctx: SavedCtx::default(),
            alternate_saved_ctx: SavedCtx::default(),
            dirty_lines,
            xtwinops: false,
        }
    }

    pub fn size(&self) -> (usize, usize) {
        (self.cols, self.rows)
    }

    pub fn active_buffer_type(&self) -> BufferType {
        self.active_buffer_type
    }

    pub fn cursor(&self) -> Cursor {
        self.cursor
    }

    pub fn gc(&mut self) -> Box<dyn Iterator<Item = Line> + '_> {
        let lines = self.buffer.gc();

        if self.active_buffer_type == BufferType::Alternate {
            return Box::new(std::iter::empty());
        }

        match lines {
            Some(iter) => Box::new(iter),
            None => Box::new(std::iter::empty()),
        }
    }

    pub fn changes(&mut self) -> Vec<usize> {
        let changes = self.dirty_lines.to_vec();
        self.dirty_lines.clear();

        changes
    }

    fn primary_buffer(&self) -> &Buffer {
        if self.active_buffer_type == BufferType::Primary {
            &self.buffer
        } else {
            &self.other_buffer
        }
    }

    fn alternate_buffer(&self) -> &Buffer {
        if self.active_buffer_type == BufferType::Alternate {
            &self.buffer
        } else {
            &self.other_buffer
        }
    }

    pub fn view(&self) -> impl Iterator<Item = &Line> {
        self.buffer.view()
    }

    pub fn lines(&self) -> impl Iterator<Item = &Line> {
        self.buffer.lines()
    }

    pub fn line(&self, n: usize) -> &Line {
        &self.buffer[n]
    }

    pub fn text(&self) -> Vec<String> {
        self.primary_buffer().text()
    }

    pub fn cursor_keys_app_mode(&self) -> bool {
        self.cursor_keys_mode == CursorKeysMode::Application
    }

    #[cfg(test)]
    pub fn verify(&self) {
        assert!(self.cursor.row < self.rows);
        assert!(self.cursor.col <= self.cols);
        assert!(self.lines().all(|line| line.len() == self.cols));
        assert!(!self.lines().last().unwrap().wrapped);

        for line in self.lines() {
            for i in 0..self.cols {
                let occupancy = line[i].occupancy();

                if occupancy == Occupancy::WideTail {
                    assert!(i > 0);
                    assert!(line[i - 1].occupancy() == Occupancy::WideHead);
                } else if occupancy == Occupancy::WideHead {
                    assert!(line[i + 1].occupancy() == Occupancy::WideTail, "{:?}", line);
                }
            }
        }
    }

    #[cfg(test)]
    pub fn assert_eq(&self, other: &Terminal) {
        assert_eq!(self.active_buffer_type, other.active_buffer_type);
        assert_eq!(self.cursor, other.cursor);
        assert_eq!(self.pen, other.pen);
        assert_eq!(self.charsets, other.charsets);
        assert_eq!(self.active_charset, other.active_charset);
        assert_eq!(self.tabs, other.tabs);
        assert_eq!(self.insert_mode, other.insert_mode);
        assert_eq!(self.origin_mode, other.origin_mode);
        assert_eq!(self.auto_wrap_mode, other.auto_wrap_mode);
        assert_eq!(self.new_line_mode, other.new_line_mode);
        assert_eq!(self.cursor_keys_mode, other.cursor_keys_mode);
        assert_eq!(self.top_margin, other.top_margin);
        assert_eq!(self.bottom_margin, other.bottom_margin);
        assert_eq!(self.saved_ctx, other.saved_ctx);
        assert_eq!(self.alternate_saved_ctx, other.alternate_saved_ctx);

        assert_eq!(
            self.primary_buffer().view().collect::<Vec<_>>(),
            other.primary_buffer().view().collect::<Vec<_>>()
        );

        if self.active_buffer_type == BufferType::Alternate {
            assert_eq!(
                self.alternate_buffer().view().collect::<Vec<_>>(),
                other.alternate_buffer().view().collect::<Vec<_>>()
            );
        }
    }

    fn print(&mut self, mut ch: char) {
        ch = self.charsets[self.active_charset].translate(ch);

        match self.try_print(ch) {
            PrintResult::Printed(width) => self.advance_cursor_after_print(width),
            PrintResult::NeedsRelocation if self.auto_wrap_mode => {
                self.wrap_and_print_at_line_start(ch)
            }
            PrintResult::NeedsRelocation => self.print_at_line_end(ch),
        }

        self.dirty_lines.add(self.cursor.row);
    }

    fn try_print(&mut self, ch: char) -> PrintResult {
        if self.cursor.col >= self.cols {
            return PrintResult::NeedsRelocation;
        }

        if self.insert_mode {
            self.buffer
                .shift_right((self.cursor.col, self.cursor.row), 1, self.pen);
        }

        match self
            .buffer
            .print((self.cursor.col, self.cursor.row), ch, self.pen)
        {
            Some(width) => PrintResult::Printed(width),
            None => PrintResult::NeedsRelocation,
        }
    }

    fn advance_cursor_after_print(&mut self, width: usize) {
        self.cursor.col += width;

        if self.cursor.col == self.cols && !self.auto_wrap_mode {
            self.cursor.col = self.cols - 1;
        }
    }

    fn wrap_and_print_at_line_start(&mut self, ch: char) {
        if self.cursor.row == self.bottom_margin {
            self.buffer.wrap(self.cursor.row);
            self.scroll_up_in_region(1);
        } else if self.cursor.row < self.rows - 1 {
            self.buffer.wrap(self.cursor.row);
            self.cursor.row += 1;
        }

        if let Some(width) = self.buffer.print((0, self.cursor.row), ch, self.pen) {
            self.cursor.col = width;
        } else {
            self.cursor.col = 0;
        }
    }

    fn print_at_line_end(&mut self, ch: char) {
        let row = self.cursor.row;

        if self.cursor.col > 0 {
            let col = self.cursor.col - 1;
            let printed = self.buffer.print((col, row), ch, self.pen).is_some();

            if !printed && col > 0 {
                self.buffer.print((col - 1, row), ch, self.pen);
            }
        }

        self.cursor.col = self.cols - 1;
    }

    fn bs(&mut self) {
        if self.cursor.col == self.cols {
            self.move_cursor_to_rel_col(-2);
        } else {
            self.move_cursor_to_rel_col(-1);
        }
    }

    fn ht(&mut self) {
        self.move_cursor_to_next_tab(1);
    }

    fn lf(&mut self) {
        self.move_cursor_down_with_scroll();

        if self.new_line_mode {
            self.cursor.col = 0;
        }
    }

    fn cr(&mut self) {
        self.cursor.col = 0;
    }

    fn so(&mut self) {
        self.active_charset = 1;
    }

    fn si(&mut self) {
        self.active_charset = 0;
    }

    fn nel(&mut self) {
        self.move_cursor_down_with_scroll();
        self.cursor.col = 0;
    }

    fn hts(&mut self) {
        self.set_tab();
    }

    fn ri(&mut self) {
        if self.cursor.row == self.top_margin {
            self.scroll_down_in_region(1);
        } else if self.cursor.row > 0 {
            self.move_cursor_to_row(self.cursor.row - 1);
        }
    }

    fn sc(&mut self) {
        self.save_cursor();
    }

    fn rc(&mut self) {
        self.restore_cursor();
    }

    fn ris(&mut self) {
        self.hard_reset();
    }

    fn decaln(&mut self) {
        for row in 0..self.rows {
            for col in 0..self.cols {
                self.buffer.print((col, row), '\u{45}', Pen::default());
            }

            self.dirty_lines.add(row);
        }
    }

    fn gzd4(&mut self, charset: Charset) {
        self.charsets[0] = charset;
    }

    fn g1d4(&mut self, charset: Charset) {
        self.charsets[1] = charset;
    }

    fn ich(&mut self, n: u16) {
        if self.cursor.col == self.cols {
            self.cursor.col = self.cols - 1;
        }

        let n = as_usize(n, 1).min(self.cols - self.cursor.col);

        self.buffer
            .shift_right((self.cursor.col, self.cursor.row), n, self.pen);

        for col in self.cursor.col..self.cursor.col + n {
            self.buffer.print((col, self.cursor.row), ' ', self.pen);
        }

        self.dirty_lines.add(self.cursor.row);
    }

    fn cuu(&mut self, n: u16) {
        self.cursor_up(as_usize(n, 1));
    }

    fn cud(&mut self, n: u16) {
        self.cursor_down(as_usize(n, 1));
    }

    fn cuf(&mut self, n: u16) {
        self.move_cursor_to_rel_col(as_usize(n, 1) as isize);
    }

    fn cub(&mut self, n: u16) {
        let mut rel_col = -(as_usize(n, 1) as isize);

        if self.cursor.col == self.cols {
            rel_col -= 1;
        }

        self.move_cursor_to_rel_col(rel_col);
    }

    fn cnl(&mut self, n: u16) {
        self.cursor_down(as_usize(n, 1));
        self.cursor.col = 0;
    }

    fn cpl(&mut self, n: u16) {
        self.cursor_up(as_usize(n, 1));
        self.cursor.col = 0;
    }

    fn cha(&mut self, n: u16) {
        self.move_cursor_to_col(as_usize(n, 1) - 1);
    }

    fn cup(&mut self, row: u16, col: u16) {
        self.move_cursor_to_col(as_usize(col, 1) - 1);
        self.move_cursor_to_row(as_usize(row, 1) - 1);
    }

    fn cht(&mut self, n: u16) {
        self.move_cursor_to_next_tab(as_usize(n, 1));
    }

    fn ed(&mut self, scope: EdScope) {
        match scope {
            EdScope::Below => {
                self.buffer.erase(
                    (self.cursor.col, self.cursor.row),
                    EraseMode::FromCursorToEndOfView,
                    &self.pen,
                );

                self.dirty_lines.extend(self.cursor.row..self.rows);
            }

            EdScope::Above => {
                self.buffer.erase(
                    (self.cursor.col, self.cursor.row),
                    EraseMode::FromStartOfViewToCursor,
                    &self.pen,
                );

                self.dirty_lines.extend(0..self.cursor.row + 1);
            }

            EdScope::All => {
                self.buffer.erase(
                    (self.cursor.col, self.cursor.row),
                    EraseMode::WholeView,
                    &self.pen,
                );

                self.dirty_lines.extend(0..self.rows);
            }

            _ => {}
        }
    }

    fn el(&mut self, scope: ElScope) {
        match scope {
            ElScope::ToRight => {
                self.buffer.erase(
                    (self.cursor.col, self.cursor.row),
                    EraseMode::FromCursorToEndOfLine,
                    &self.pen,
                );

                self.dirty_lines.add(self.cursor.row);
            }

            ElScope::ToLeft => {
                self.buffer.erase(
                    (self.cursor.col, self.cursor.row),
                    EraseMode::FromStartOfLineToCursor,
                    &self.pen,
                );

                self.dirty_lines.add(self.cursor.row);
            }

            ElScope::All => {
                self.buffer.erase(
                    (self.cursor.col, self.cursor.row),
                    EraseMode::WholeLine,
                    &self.pen,
                );

                self.dirty_lines.add(self.cursor.row);
            }
        }
    }

    fn il(&mut self, n: u16) {
        let range = if self.cursor.row <= self.bottom_margin {
            self.cursor.row..self.bottom_margin + 1
        } else {
            self.cursor.row..self.rows
        };

        self.buffer
            .scroll_down(range.clone(), as_usize(n, 1), &self.pen);

        self.dirty_lines.extend(range);
    }

    fn dl(&mut self, n: u16) {
        let range = if self.cursor.row <= self.bottom_margin {
            self.cursor.row..self.bottom_margin + 1
        } else {
            self.cursor.row..self.rows
        };

        self.buffer
            .scroll_up(range.clone(), as_usize(n, 1), &self.pen);

        self.dirty_lines.extend(range);
    }

    fn dch(&mut self, n: u16) {
        if self.cursor.col >= self.cols {
            self.move_cursor_to_col(self.cols - 1);
        }

        self.buffer.delete(
            (self.cursor.col, self.cursor.row),
            as_usize(n, 1),
            &self.pen,
        );

        self.dirty_lines.add(self.cursor.row);
    }

    fn su(&mut self, n: u16) {
        self.scroll_up_in_region(as_usize(n, 1));
    }

    fn sd(&mut self, n: u16) {
        self.scroll_down_in_region(as_usize(n, 1));
    }

    fn ctc(&mut self, op: CtcOp) {
        match op {
            CtcOp::Set => {
                self.set_tab();
            }

            CtcOp::ClearCurrentColumn => {
                self.clear_tab();
            }

            CtcOp::ClearAll => {
                self.clear_all_tabs();
            }
        }
    }

    fn ech(&mut self, n: u16) {
        let n = as_usize(n, 1);

        self.buffer.erase(
            (self.cursor.col, self.cursor.row),
            EraseMode::NextChars(n),
            &self.pen,
        );

        self.dirty_lines.add(self.cursor.row);
    }

    fn cbt(&mut self, n: u16) {
        self.move_cursor_to_prev_tab(as_usize(n, 1));
    }

    fn rep(&mut self, n: u16) {
        if self.cursor.col > 0 {
            let n = as_usize(n, 1);
            let row = self.cursor.row;
            let mut col = self.cursor.col - 1;

            while col > 0 && self.buffer[(col, row)].occupancy() == Occupancy::WideTail {
                col -= 1;
            }

            let char = self.buffer[(col, row)].char();

            for _n in 0..n {
                self.print(char);
            }
        }
    }

    fn vpa(&mut self, n: u16) {
        self.move_cursor_to_row(as_usize(n, 1) - 1);
    }

    fn vpr(&mut self, n: u16) {
        self.cursor_down(as_usize(n, 1));
    }

    fn tbc(&mut self, scope: TbcScope) {
        match scope {
            TbcScope::CurrentColumn => {
                self.clear_tab();
            }

            TbcScope::All => {
                self.clear_all_tabs();
            }
        }
    }

    fn sm(&mut self, modes: AnsiModes) {
        use AnsiMode::*;

        for &mode in modes.as_slice() {
            match mode {
                Insert => {
                    self.insert_mode = true;
                }

                NewLine => {
                    self.new_line_mode = true;
                }
            }
        }
    }

    fn rm(&mut self, modes: AnsiModes) {
        use AnsiMode::*;

        for &mode in modes.as_slice() {
            match mode {
                Insert => {
                    self.insert_mode = false;
                }

                NewLine => {
                    self.new_line_mode = false;
                }
            }
        }
    }

    fn sgr(&mut self, ops: SgrOps) {
        use SgrOp::*;

        for &op in ops.as_slice() {
            match op {
                Reset => {
                    self.pen = Pen::default();
                }

                SetBoldIntensity => {
                    self.pen.intensity = Intensity::Bold;
                }

                SetFaintIntensity => {
                    self.pen.intensity = Intensity::Faint;
                }

                SetItalic => {
                    self.pen.set_italic();
                }

                SetUnderline => {
                    self.pen.set_underline();
                }

                SetBlink => {
                    self.pen.set_blink();
                }

                SetInverse => {
                    self.pen.set_inverse();
                }

                SetStrikethrough => {
                    self.pen.set_strikethrough();
                }

                ResetIntensity => {
                    self.pen.intensity = Intensity::Normal;
                }

                ResetItalic => {
                    self.pen.unset_italic();
                }

                ResetUnderline => {
                    self.pen.unset_underline();
                }

                ResetBlink => {
                    self.pen.unset_blink();
                }

                ResetInverse => {
                    self.pen.unset_inverse();
                }

                ResetStrikethrough => {
                    self.pen.unset_strikethrough();
                }

                SetForegroundColor(color) => {
                    self.pen.foreground = Some(color);
                }

                ResetForegroundColor => {
                    self.pen.foreground = None;
                }

                SetBackgroundColor(color) => {
                    self.pen.background = Some(color);
                }

                ResetBackgroundColor => {
                    self.pen.background = None;
                }
            }
        }
    }

    fn decstbm(&mut self, top: u16, bottom: u16) {
        let top = as_usize(top, 1) - 1;
        let bottom = as_usize(bottom, self.rows) - 1;

        if top < bottom && bottom < self.rows {
            self.top_margin = top;
            self.bottom_margin = bottom;
        }

        self.move_cursor_home();
    }

    fn xtwinops(&mut self, op: XtwinopsOp) {
        if self.xtwinops {
            let XtwinopsOp::Resize(cols, rows) = op;
            let cols = as_usize(cols, self.cols);
            let rows = as_usize(rows, self.rows);

            self.resize(cols, rows);
        }
    }

    fn decstr(&mut self) {
        self.soft_reset();
    }

    fn decset(&mut self, modes: DecModes) {
        use DecMode::*;

        for &mode in modes.as_slice() {
            match mode {
                CursorKeys => {
                    self.cursor_keys_mode = CursorKeysMode::Application;
                }

                Origin => {
                    self.origin_mode = true;
                    self.move_cursor_home();
                }

                AutoWrap => {
                    self.auto_wrap_mode = true;
                }

                TextCursorEnable => {
                    self.cursor.visible = true;
                }

                AltScreenBuffer => {
                    self.switch_to_alternate_buffer();
                    self.reflow();
                }

                SaveCursor => {
                    self.save_cursor();
                }

                SaveCursorAltScreenBuffer => {
                    self.save_cursor();
                    self.switch_to_alternate_buffer();
                    self.reflow();
                }
            }
        }
    }

    fn decrst(&mut self, modes: DecModes) {
        use DecMode::*;

        for &mode in modes.as_slice() {
            match mode {
                CursorKeys => {
                    self.cursor_keys_mode = CursorKeysMode::Normal;
                }

                Origin => {
                    self.origin_mode = false;
                    self.move_cursor_home();
                }

                AutoWrap => {
                    self.auto_wrap_mode = false;
                }

                TextCursorEnable => {
                    self.cursor.visible = false;
                }

                AltScreenBuffer => {
                    self.switch_to_primary_buffer();
                    self.reflow();
                }

                SaveCursor => {
                    self.restore_cursor();
                }

                SaveCursorAltScreenBuffer => {
                    self.switch_to_primary_buffer();
                    self.restore_cursor();
                    self.reflow();
                }
            }
        }
    }
}

fn as_u16(value: usize) -> u16 {
    value
        .try_into()
        .expect("terminal dump parameter exceeds u16 range")
}

fn as_usize(value: u16, default: usize) -> usize {
    if value == 0 {
        default
    } else {
        value as usize
    }
}

impl Default for Terminal {
    fn default() -> Self {
        Self::new((80, 24), None)
    }
}

#[cfg(test)]
mod tests;
