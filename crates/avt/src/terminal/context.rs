use crate::pen::Pen;

#[derive(Debug, PartialEq)]
pub(crate) struct SavedCtx {
    pub cursor_col: usize,
    pub cursor_row: usize,
    pub pen: Pen,
    pub origin_mode: bool,
    pub auto_wrap_mode: bool,
}

impl Default for SavedCtx {
    fn default() -> Self {
        SavedCtx {
            cursor_col: 0,
            cursor_row: 0,
            pen: Pen::default(),
            origin_mode: false,
            auto_wrap_mode: true,
        }
    }
}

impl SavedCtx {
    pub(crate) fn is_default(&self) -> bool {
        self.cursor_col == 0
            && self.cursor_row == 0
            && self.pen.is_default()
            && !self.origin_mode
            && self.auto_wrap_mode
    }
}
