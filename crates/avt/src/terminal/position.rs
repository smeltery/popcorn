use super::Terminal;

impl Terminal {
    pub(super) fn save_cursor(&mut self) {
        self.saved_ctx.cursor_col = self.cursor.col.min(self.cols - 1);
        self.saved_ctx.cursor_row = self.cursor.row;
        self.saved_ctx.pen = self.pen;
        self.saved_ctx.origin_mode = self.origin_mode;
        self.saved_ctx.auto_wrap_mode = self.auto_wrap_mode;
    }

    pub(super) fn restore_cursor(&mut self) {
        self.cursor.col = self.saved_ctx.cursor_col;
        self.cursor.row = self.saved_ctx.cursor_row;
        self.pen = self.saved_ctx.pen;
        self.origin_mode = self.saved_ctx.origin_mode;
        self.auto_wrap_mode = self.saved_ctx.auto_wrap_mode;
    }

    pub(super) fn move_cursor_to_col(&mut self, col: usize) {
        if col >= self.cols {
            self.cursor.col = self.cols - 1;
        } else {
            self.cursor.col = col;
        }
    }

    pub(super) fn move_cursor_to_row(&mut self, mut row: usize) {
        let top = self.actual_top_margin();
        let bottom = self.actual_bottom_margin();
        row = (top + row).max(top).min(bottom);
        self.do_move_cursor_to_row(row);
    }

    pub(super) fn do_move_cursor_to_row(&mut self, row: usize) {
        self.cursor.col = self.cursor.col.min(self.cols - 1);
        self.cursor.row = row;
    }

    pub(super) fn move_cursor_to_rel_col(&mut self, rel_col: isize) {
        let new_col = self.cursor.col as isize + rel_col;

        if new_col < 0 {
            self.cursor.col = 0;
        } else if new_col as usize >= self.cols {
            self.cursor.col = self.cols - 1;
        } else {
            self.cursor.col = new_col as usize;
        }
    }

    pub(super) fn move_cursor_home(&mut self) {
        self.cursor.col = 0;
        self.do_move_cursor_to_row(self.actual_top_margin());
    }

    pub(super) fn move_cursor_to_next_tab(&mut self, n: usize) {
        let next_tab = self.tabs.after(self.cursor.col, n).unwrap_or(self.cols - 1);
        self.move_cursor_to_col(next_tab);
    }

    pub(super) fn move_cursor_to_prev_tab(&mut self, n: usize) {
        let prev_tab = self.tabs.before(self.cursor.col, n).unwrap_or(0);
        self.move_cursor_to_col(prev_tab);
    }

    pub(super) fn move_cursor_down_with_scroll(&mut self) {
        if self.cursor.row == self.bottom_margin {
            self.scroll_up_in_region(1);
        } else if self.cursor.row < self.rows - 1 {
            self.do_move_cursor_to_row(self.cursor.row + 1);
        }
    }

    pub(super) fn cursor_down(&mut self, n: usize) {
        let new_y = if self.cursor.row > self.bottom_margin {
            (self.rows - 1).min(self.cursor.row + n)
        } else {
            self.bottom_margin.min(self.cursor.row + n)
        };

        self.do_move_cursor_to_row(new_y);
    }

    pub(super) fn cursor_up(&mut self, n: usize) {
        let mut new_y = (self.cursor.row as isize) - (n as isize);

        new_y = if self.cursor.row < self.top_margin {
            new_y.max(0)
        } else {
            new_y.max(self.top_margin as isize)
        };

        self.do_move_cursor_to_row(new_y as usize);
    }

    pub(super) fn actual_top_margin(&self) -> usize {
        match self.origin_mode {
            false => 0,
            true => self.top_margin,
        }
    }

    pub(super) fn actual_bottom_margin(&self) -> usize {
        match self.origin_mode {
            false => self.rows - 1,
            true => self.bottom_margin,
        }
    }

    pub(super) fn scroll_up_in_region(&mut self, n: usize) {
        let range = self.top_margin..self.bottom_margin + 1;
        self.buffer.scroll_up(range.clone(), n, &self.pen);
        self.dirty_lines.extend(range);
    }

    pub(super) fn scroll_down_in_region(&mut self, n: usize) {
        let range = self.top_margin..self.bottom_margin + 1;
        self.buffer.scroll_down(range.clone(), n, &self.pen);
        self.dirty_lines.extend(range);
    }

    pub(super) fn set_tab(&mut self) {
        if 0 < self.cursor.col && self.cursor.col < self.cols {
            self.tabs.set(self.cursor.col);
        }
    }

    pub(super) fn clear_tab(&mut self) {
        self.tabs.unset(self.cursor.col);
    }

    pub(super) fn clear_all_tabs(&mut self) {
        self.tabs.clear();
    }
}
