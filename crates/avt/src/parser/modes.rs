use crate::color::Color;

#[derive(Debug, Copy, Clone, PartialEq)]
#[repr(u16)]
pub enum AnsiMode {
    Insert = 4,   // IRM
    NewLine = 20, // LNM
}

#[derive(Debug, Copy, Clone, PartialEq)]
#[repr(u16)]
pub enum DecMode {
    CursorKeys = 1,                   // DECCKM
    Origin = 6,                       // DECOM
    AutoWrap = 7,                     // DECAWM
    TextCursorEnable = 25,            // DECTCEM
    AltScreenBuffer = 1047,           // xterm
    SaveCursor = 1048,                // xterm
    SaveCursorAltScreenBuffer = 1049, // xterm
}

#[derive(Debug, PartialEq, Clone, Copy)]
pub enum SgrOp {
    Reset,                     // 0
    SetBoldIntensity,          // 1
    SetFaintIntensity,         // 2
    SetItalic,                 // 3
    SetUnderline,              // 4
    SetBlink,                  // 5
    SetInverse,                // 7
    SetStrikethrough,          // 9
    ResetIntensity,            // 21, 22
    ResetItalic,               // 23
    ResetUnderline,            // 24
    ResetBlink,                // 25
    ResetInverse,              // 27
    ResetStrikethrough,        // 29
    SetForegroundColor(Color), // 30-38
    ResetForegroundColor,      // 39
    SetBackgroundColor(Color), // 40-48
    ResetBackgroundColor,      // 49
}

/// Number of SgrOp values that fit inline without heap allocation.
pub const SGR_OPS_INLINE_CAP: usize = 4;

/// Small-buffer-optimized collection of SgrOp values.
#[derive(Debug, Clone, PartialEq)]
pub struct SgrOps(SgrOpsStorage);

#[derive(Debug, Clone, PartialEq)]
enum SgrOpsStorage {
    Inline {
        ops: [SgrOp; SGR_OPS_INLINE_CAP],
        len: u8,
    },
    Heap(Vec<SgrOp>),
}

impl SgrOps {
    pub(crate) fn new() -> Self {
        Self(SgrOpsStorage::Inline {
            ops: [SgrOp::Reset; SGR_OPS_INLINE_CAP],
            len: 0,
        })
    }

    pub(crate) fn collect<I: IntoIterator<Item = SgrOp>>(iter: I) -> Self {
        let mut ops = Self::new();

        for op in iter {
            ops.push(op);
        }

        ops
    }

    pub(crate) fn len(&self) -> usize {
        match &self.0 {
            SgrOpsStorage::Inline { len, .. } => *len as usize,
            SgrOpsStorage::Heap(v) => v.len(),
        }
    }

    pub(crate) fn is_empty(&self) -> bool {
        self.len() == 0
    }

    pub(crate) fn as_slice(&self) -> &[SgrOp] {
        match &self.0 {
            SgrOpsStorage::Inline { ops, len } => &ops[..*len as usize],
            SgrOpsStorage::Heap(v) => v.as_slice(),
        }
    }

    pub(crate) fn push(&mut self, op: SgrOp) {
        match &mut self.0 {
            SgrOpsStorage::Inline { ops, len } => {
                if (*len as usize) < SGR_OPS_INLINE_CAP {
                    ops[*len as usize] = op;
                    *len += 1;
                } else {
                    let mut v = Vec::with_capacity(SGR_OPS_INLINE_CAP * 2);
                    v.extend_from_slice(ops);
                    v.push(op);
                    self.0 = SgrOpsStorage::Heap(v);
                }
            }
            SgrOpsStorage::Heap(v) => v.push(op),
        }
    }
}

impl From<Vec<SgrOp>> for SgrOps {
    fn from(v: Vec<SgrOp>) -> Self {
        if v.len() <= SGR_OPS_INLINE_CAP {
            Self::collect(v)
        } else {
            Self(SgrOpsStorage::Heap(v))
        }
    }
}

impl From<&[SgrOp]> for SgrOps {
    fn from(v: &[SgrOp]) -> Self {
        Self::collect(v.iter().copied())
    }
}

/// Number of mode values that fit inline without heap allocation.
pub const MODES_INLINE_CAP: usize = 4;

/// Small-buffer-optimized collection of mode values.
#[derive(Debug, Clone, PartialEq)]
pub struct AnsiModes(AnsiModesStorage);

#[derive(Debug, Clone, PartialEq)]
enum AnsiModesStorage {
    Inline {
        modes: [AnsiMode; MODES_INLINE_CAP],
        len: u8,
    },
    Heap(Vec<AnsiMode>),
}

impl AnsiModes {
    pub(crate) fn new() -> Self {
        Self(AnsiModesStorage::Inline {
            modes: [AnsiMode::Insert; MODES_INLINE_CAP],
            len: 0,
        })
    }

    pub(crate) fn one(mode: AnsiMode) -> Self {
        let mut modes = Self::new();
        modes.push(mode);
        modes
    }

    pub(crate) fn collect<I: IntoIterator<Item = AnsiMode>>(iter: I) -> Self {
        let mut v = Self::new();

        for m in iter {
            v.push(m);
        }

        v
    }

    pub(crate) fn as_slice(&self) -> &[AnsiMode] {
        match &self.0 {
            AnsiModesStorage::Inline { modes, len } => &modes[..*len as usize],
            AnsiModesStorage::Heap(v) => v.as_slice(),
        }
    }

    pub(crate) fn push(&mut self, m: AnsiMode) {
        match &mut self.0 {
            AnsiModesStorage::Inline { modes, len } => {
                if (*len as usize) < MODES_INLINE_CAP {
                    modes[*len as usize] = m;
                    *len += 1;
                } else {
                    let mut v = Vec::with_capacity(MODES_INLINE_CAP * 2);
                    v.extend_from_slice(modes);
                    v.push(m);
                    self.0 = AnsiModesStorage::Heap(v);
                }
            }
            AnsiModesStorage::Heap(v) => v.push(m),
        }
    }
}

impl From<Vec<AnsiMode>> for AnsiModes {
    fn from(v: Vec<AnsiMode>) -> Self {
        if v.len() <= MODES_INLINE_CAP {
            Self::collect(v)
        } else {
            Self(AnsiModesStorage::Heap(v))
        }
    }
}

impl From<&[AnsiMode]> for AnsiModes {
    fn from(v: &[AnsiMode]) -> Self {
        Self::collect(v.iter().copied())
    }
}

/// Small-buffer-optimized collection of DEC mode values.
#[derive(Debug, Clone, PartialEq)]
pub struct DecModes(DecModesStorage);

#[derive(Debug, Clone, PartialEq)]
enum DecModesStorage {
    Inline {
        modes: [DecMode; MODES_INLINE_CAP],
        len: u8,
    },
    Heap(Vec<DecMode>),
}

impl DecModes {
    pub(crate) fn new() -> Self {
        Self(DecModesStorage::Inline {
            modes: [DecMode::CursorKeys; MODES_INLINE_CAP],
            len: 0,
        })
    }

    pub(crate) fn one(mode: DecMode) -> Self {
        let mut modes = Self::new();
        modes.push(mode);
        modes
    }

    pub(crate) fn collect<I: IntoIterator<Item = DecMode>>(iter: I) -> Self {
        let mut v = Self::new();

        for m in iter {
            v.push(m);
        }

        v
    }

    pub(crate) fn as_slice(&self) -> &[DecMode] {
        match &self.0 {
            DecModesStorage::Inline { modes, len } => &modes[..*len as usize],
            DecModesStorage::Heap(v) => v.as_slice(),
        }
    }

    pub(crate) fn push(&mut self, m: DecMode) {
        match &mut self.0 {
            DecModesStorage::Inline { modes, len } => {
                if (*len as usize) < MODES_INLINE_CAP {
                    modes[*len as usize] = m;
                    *len += 1;
                } else {
                    let mut v = Vec::with_capacity(MODES_INLINE_CAP * 2);
                    v.extend_from_slice(modes);
                    v.push(m);
                    self.0 = DecModesStorage::Heap(v);
                }
            }
            DecModesStorage::Heap(v) => v.push(m),
        }
    }
}

impl From<Vec<DecMode>> for DecModes {
    fn from(v: Vec<DecMode>) -> Self {
        if v.len() <= MODES_INLINE_CAP {
            Self::collect(v)
        } else {
            Self(DecModesStorage::Heap(v))
        }
    }
}

impl From<&[DecMode]> for DecModes {
    fn from(v: &[DecMode]) -> Self {
        Self::collect(v.iter().copied())
    }
}
