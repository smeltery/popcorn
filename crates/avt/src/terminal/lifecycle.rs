use std::mem;

use super::{BufferType, Cursor, CursorKeysMode, DirtyLines, SavedCtx, Terminal};
use crate::buffer::Buffer;
use crate::charset::Charset;
use crate::pen::Pen;
use crate::tabs::Tabs;

impl Terminal {
    pub(super) fn switch_to_alternate_buffer(&mut self) {
        if let BufferType::Primary = self.active_buffer_type {
            self.active_buffer_type = BufferType::Alternate;
            mem::swap(&mut self.saved_ctx, &mut self.alternate_saved_ctx);
            mem::swap(&mut self.buffer, &mut self.other_buffer);
            self.buffer = Buffer::new(self.cols, self.rows, Some(0), Some(&self.pen));
            self.dirty_lines.extend(0..self.rows);
        }
    }

    pub(super) fn switch_to_primary_buffer(&mut self) {
        if let BufferType::Alternate = self.active_buffer_type {
            self.active_buffer_type = BufferType::Primary;
            mem::swap(&mut self.saved_ctx, &mut self.alternate_saved_ctx);
            mem::swap(&mut self.buffer, &mut self.other_buffer);
            self.dirty_lines.extend(0..self.rows);
        }
    }

    // resizing

    pub fn resize(&mut self, cols: usize, rows: usize) -> bool {
        let mut resized: bool = false;

        match cols.cmp(&self.cols) {
            std::cmp::Ordering::Less => {
                self.tabs.contract(cols);
                resized = true;
            }

            std::cmp::Ordering::Equal => {}

            std::cmp::Ordering::Greater => {
                self.tabs.expand(self.cols, cols);
                resized = true;
            }
        }

        match rows.cmp(&self.rows) {
            std::cmp::Ordering::Less => {
                self.top_margin = 0;
                self.bottom_margin = rows - 1;
                resized = true;
            }

            std::cmp::Ordering::Equal => {}

            std::cmp::Ordering::Greater => {
                self.top_margin = 0;
                self.bottom_margin = rows - 1;
                resized = true;
            }
        }

        self.cols = cols;
        self.rows = rows;
        self.reflow();

        resized
    }

    pub(super) fn reflow(&mut self) {
        (self.cursor.col, self.cursor.row) =
            self.buffer
                .resize(self.cols, self.rows, (self.cursor.col, self.cursor.row));

        self.dirty_lines.resize(self.rows);
        self.dirty_lines.extend(0..self.rows);

        if self.saved_ctx.cursor_col >= self.cols {
            self.saved_ctx.cursor_col = self.cols - 1;
        }

        if self.saved_ctx.cursor_row >= self.rows {
            self.saved_ctx.cursor_row = self.rows - 1;
        }
    }

    // resetting

    pub(super) fn soft_reset(&mut self) {
        self.cursor.visible = true;
        self.top_margin = 0;
        self.bottom_margin = self.rows - 1;
        self.insert_mode = false;
        self.origin_mode = false;
        self.pen = Pen::default();
        self.charsets = [Charset::Ascii, Charset::Ascii];
        self.active_charset = 0;
        self.saved_ctx = SavedCtx::default();
    }

    pub(super) fn hard_reset(&mut self) {
        let primary_buffer = Buffer::new(self.cols, self.rows, self.scrollback_limit, None);
        let alternate_buffer = Buffer::new(self.cols, self.rows, Some(0), None);

        self.buffer = primary_buffer;
        self.other_buffer = alternate_buffer;
        self.active_buffer_type = BufferType::Primary;
        self.tabs = Tabs::new(self.cols);
        self.cursor = Cursor::default();
        self.pen = Pen::default();
        self.charsets = [Charset::Ascii, Charset::Ascii];
        self.active_charset = 0;
        self.insert_mode = false;
        self.origin_mode = false;
        self.auto_wrap_mode = true;
        self.new_line_mode = false;
        self.cursor_keys_mode = CursorKeysMode::Normal;
        self.top_margin = 0;
        self.bottom_margin = self.rows - 1;
        self.saved_ctx = SavedCtx::default();
        self.alternate_saved_ctx = SavedCtx::default();
        self.dirty_lines = DirtyLines::new(self.rows);
    }
}
