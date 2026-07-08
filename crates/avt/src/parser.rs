// Based on Paul Williams' parser for ANSI-compatible video terminals:
// https://www.vt100.net/emu/dec_ansi_parser

mod dispatch;
mod dump;
mod modes;

use crate::charset::Charset;
use std::fmt::Display;

pub(crate) use dump::dump;
pub use modes::{
    AnsiMode, AnsiModes, DecMode, DecModes, SgrOp, SgrOps, MODES_INLINE_CAP, SGR_OPS_INLINE_CAP,
};

const PARAMS_LEN: usize = 32;

#[derive(Debug, Default)]
pub struct Parser {
    pub state: State,
    params: [Param; PARAMS_LEN],
    cur_param: usize,
    intermediate: Option<char>,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Default)]
pub enum State {
    #[default]
    Ground,
    Escape,
    EscapeIntermediate,
    CsiEntry,
    CsiParam,
    CsiIntermediate,
    CsiIgnore,
    DcsEntry,
    DcsParam,
    DcsIntermediate,
    DcsPassthrough,
    DcsIgnore,
    OscString,
    SosPmApcString,
}

#[derive(Debug, PartialEq)]
pub enum Function {
    Bs,
    Cbt(u16),
    Cha(u16),
    Cht(u16),
    Cnl(u16),
    Cpl(u16),
    Cr,
    Ctc(CtcOp),
    Cub(u16),
    Cud(u16),
    Cuf(u16),
    Cup(u16, u16),
    Cuu(u16),
    Dch(u16),
    Decaln,
    Decrc,
    Decrst(DecModes),
    Decsc,
    Decset(DecModes),
    Decstbm(u16, u16),
    Decstr,
    Dl(u16),
    Ech(u16),
    Ed(EdScope),
    El(ElScope),
    G1d4(Charset),
    Gzd4(Charset),
    Ht,
    Hts,
    Ich(u16),
    Il(u16),
    Lf,
    Nel,
    Print(char),
    Rep(u16),
    Ri,
    Ris,
    Rm(AnsiModes),
    Scorc,
    Scosc,
    Sd(u16),
    Sgr(SgrOps),
    Si,
    Sm(AnsiModes),
    So,
    Su(u16),
    Tbc(TbcScope),
    Vpa(u16),
    Vpr(u16),
    Xtwinops(XtwinopsOp),
}

#[derive(Debug, PartialEq)]
pub enum CtcOp {
    Set,
    ClearCurrentColumn,
    ClearAll,
}

#[derive(Debug, PartialEq)]
pub enum EdScope {
    Below,
    Above,
    All,
    SavedLines,
}

#[derive(Debug, PartialEq)]
pub enum ElScope {
    ToRight,
    ToLeft,
    All,
}

#[derive(Debug, PartialEq)]
pub enum TbcScope {
    CurrentColumn,
    All,
}

#[derive(Debug, PartialEq)]
pub enum XtwinopsOp {
    Resize(u16, u16),
}

impl Parser {
    pub fn new() -> Self {
        Default::default()
    }

    pub fn feed(&mut self, input: char) -> Option<Function> {
        use State::*;

        let input2 = if input >= '\u{a0}' { '\u{41}' } else { input };

        match (&self.state, input2) {
            (Ground, '\u{20}'..='\u{7f}') => {
                return Some(Function::Print(input));
            }

            (CsiParam, '\u{30}'..='\u{3b}') => {
                self.param(input);
            }

            (_, '\u{1b}') => {
                self.state = Escape;
                self.clear();
            }

            (Escape, '\u{5b}') => {
                self.state = CsiEntry;
                self.clear();
            }

            (CsiParam | CsiEntry | CsiIntermediate, '\u{40}'..='\u{7e}') => {
                self.state = Ground;
                return self.csi_dispatch(input);
            }

            (CsiEntry, '\u{30}'..='\u{39}') | (CsiEntry, '\u{3b}') => {
                self.state = CsiParam;
                self.param(input);
            }

            (Ground, '\u{00}'..='\u{17}') | (Ground, '\u{19}') | (Ground, '\u{1c}'..='\u{1f}') => {
                return self.execute(input);
            }

            (OscString, '\u{20}'..='\u{7f}') => {
                self.osc_put(input);
            }

            (Escape, '\u{20}'..='\u{2f}') => {
                self.state = EscapeIntermediate;
                self.collect(input);
            }

            (EscapeIntermediate, '\u{30}'..='\u{7e}')
            | (Escape, '\u{30}'..='\u{4f}')
            | (Escape, '\u{51}'..='\u{57}')
            | (Escape, '\u{59}')
            | (Escape, '\u{5a}')
            | (Escape, '\u{5c}')
            | (Escape, '\u{60}'..='\u{7e}') => {
                self.state = Ground;
                return self.esc_dispatch(input);
            }

            (CsiEntry, '\u{3c}'..='\u{3f}') => {
                self.state = CsiParam;
                self.collect(input);
            }

            (DcsPassthrough, '\u{00}'..='\u{17}')
            | (DcsPassthrough, '\u{19}')
            | (DcsPassthrough, '\u{1c}'..='\u{7e}') => {
                self.put(input);
            }

            (CsiIgnore, '\u{40}'..='\u{7e}') => {
                self.state = Ground;
            }

            (CsiParam, '\u{3c}'..='\u{3f}')
            | (CsiIntermediate, '\u{30}'..='\u{3f}')
            | (CsiEntry, '\u{3a}') => {
                self.state = CsiIgnore;
            }

            (Escape, '\u{5d}') => {
                self.state = OscString;
            }

            (OscString, '\u{07}') => {
                // 0x07 is xterm non-ANSI variant of transition to ground
                self.state = Ground;
            }

            (_, '\u{18}')
            | (_, '\u{1a}')
            | (_, '\u{80}'..='\u{8f}')
            | (_, '\u{91}'..='\u{97}')
            | (_, '\u{99}')
            | (_, '\u{9a}') => {
                self.state = Ground;
                return self.execute(input);
            }

            (Escape, '\u{50}') => {
                self.state = DcsEntry;
                self.clear();
            }

            (CsiParam | CsiEntry, '\u{20}'..='\u{2f}') => {
                self.state = CsiIntermediate;
                self.collect(input);
            }

            (DcsParam, '\u{30}'..='\u{39}') | (DcsParam, '\u{3b}') => {
                self.param(input);
            }

            (DcsEntry, '\u{3c}'..='\u{3f}') => {
                self.state = DcsParam;
                self.collect(input);
            }

            (DcsEntry | DcsParam | DcsIntermediate, '\u{40}'..='\u{7e}') => {
                self.state = DcsPassthrough;
            }

            (DcsEntry | DcsParam, '\u{20}'..='\u{2f}') => {
                self.state = DcsIntermediate;
                self.collect(input);
            }

            (CsiIntermediate | EscapeIntermediate | DcsIntermediate, '\u{20}'..='\u{2f}') => {
                self.collect(input);
            }

            (DcsEntry, '\u{3a}')
            | (DcsIntermediate, '\u{30}'..='\u{3f}')
            | (DcsParam, '\u{3a}')
            | (DcsParam, '\u{3c}'..='\u{3f}') => {
                self.state = DcsIgnore;
            }

            (DcsEntry, '\u{30}'..='\u{39}') | (DcsEntry, '\u{3b}') => {
                self.state = DcsParam;
                self.param(input);
            }

            (Escape | EscapeIntermediate
            | CsiEntry | CsiParam | CsiIntermediate | CsiIgnore,
            '\u{00}'..='\u{17}')
            | (Escape | EscapeIntermediate
            | CsiEntry | CsiParam | CsiIntermediate | CsiIgnore,
            '\u{19}')
            | (Escape | EscapeIntermediate
            | CsiEntry | CsiParam | CsiIntermediate | CsiIgnore,
            '\u{1c}'..='\u{1f}') => {
                return self.execute(input);
            }

            (Escape, '\u{58}') | (Escape, '\u{5e}') | (Escape, '\u{5f}') => {
                self.state = SosPmApcString;
            }

            (_, '\u{98}') | (_, '\u{9e}') | (_, '\u{9f}') => {
                self.state = SosPmApcString;
            }

            (_, '\u{9c}') => {
                self.state = Ground;
            }

            (_, '\u{9d}') => {
                self.state = OscString;
            }

            (_, '\u{90}') => {
                self.state = DcsEntry;
                self.clear();
            }

            (_, '\u{9b}') => {
                self.state = CsiEntry;
                self.clear();
            }

            // DEL (0x7F) is ignored in all states except Ground and OscString
            (Escape | EscapeIntermediate
            | CsiEntry | CsiParam | CsiIntermediate | CsiIgnore
            | DcsEntry | DcsParam | DcsIntermediate | DcsPassthrough | DcsIgnore
            | SosPmApcString, '\u{7f}')

            // CsiIgnore: params and intermediates range ignored
            | (CsiIgnore, '\u{20}'..='\u{3f}')

            // C0 controls ignored in DCS entry/param/intermediate
            | (DcsEntry | DcsParam | DcsIntermediate, '\u{00}'..='\u{17}')
            | (DcsEntry | DcsParam | DcsIntermediate, '\u{19}')
            | (DcsEntry | DcsParam | DcsIntermediate, '\u{1c}'..='\u{1f}')

            // C0 controls and printable range ignored in DcsIgnore and SosPmApcString
            | (DcsIgnore | SosPmApcString, '\u{00}'..='\u{17}')
            | (DcsIgnore | SosPmApcString, '\u{19}')
            | (DcsIgnore | SosPmApcString, '\u{1c}'..='\u{7e}')

            // Some C0 controls ignored in OscString (0x07 handled above as xterm ST)
            | (OscString, '\u{00}'..='\u{06}')
            | (OscString, '\u{08}'..='\u{17}')
            | (OscString, '\u{19}')
            | (OscString, '\u{1c}'..='\u{1f}') => {}

            // input2 is always < 0xA0 due to the mapping above
            (Ground | Escape | EscapeIntermediate
            | CsiEntry | CsiParam | CsiIntermediate | CsiIgnore
            | DcsEntry | DcsParam | DcsIntermediate | DcsPassthrough | DcsIgnore
            | OscString | SosPmApcString, '\u{a0}'..='\u{10ffff}') => {
                unreachable!()
            }
        }

        None
    }

    #[cfg(test)]
    pub fn assert_eq(&self, other: &Parser) {
        use State::*;

        assert_eq!(self.state, other.state);

        if self.state == CsiParam || self.state == DcsParam {
            assert_eq!(self.params, other.params);
        }

        if self.state == EscapeIntermediate
            || self.state == CsiIntermediate
            || self.state == CsiParam
            || self.state == DcsIntermediate
            || self.state == DcsParam
        {
            assert_eq!(self.intermediate, other.intermediate);
        }
    }
}

const MAX_PARAM_LEN: usize = 6;

#[derive(Debug, Copy, Clone, PartialEq)]
struct Param {
    cur_part: usize,
    pub parts: [u16; MAX_PARAM_LEN],
}

impl Param {
    pub fn new(number: u16) -> Self {
        Self {
            cur_part: 0,
            parts: [number, 0, 0, 0, 0, 0],
        }
    }

    pub fn clear(&mut self) {
        self.parts[..=self.cur_part].fill(0);
        self.cur_part = 0;
    }

    pub fn add_part(&mut self) {
        self.cur_part = (self.cur_part + 1).min(5);
    }

    pub fn add_digit(&mut self, input: u8) {
        let number = &mut self.parts[self.cur_part];
        *number = (10 * (*number as u32) + (input as u32)) as u16;
    }

    pub fn as_u16(&self) -> u16 {
        self.parts[0]
    }

    pub fn parts(&self) -> &[u16] {
        &self.parts[..=self.cur_part]
    }
}

impl Display for Param {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self.parts() {
            [] => unreachable!(),

            [part] => write!(f, "{}", part),

            [first, rest @ ..] => {
                write!(f, "{first}")?;

                for part in rest {
                    write!(f, ":{part}")?;
                }

                Ok(())
            }
        }
    }
}

impl Default for Param {
    fn default() -> Self {
        Self::new(0)
    }
}

impl From<u16> for Param {
    fn from(value: u16) -> Self {
        Self::new(value)
    }
}

impl From<Vec<u16>> for Param {
    fn from(values: Vec<u16>) -> Self {
        let mut parts = [0u16; MAX_PARAM_LEN];
        let mut cur_part = 0;

        for (i, v) in values.iter().take(MAX_PARAM_LEN).enumerate() {
            cur_part = i;
            parts[i] = *v;
        }

        Self { cur_part, parts }
    }
}

impl PartialEq<u16> for Param {
    fn eq(&self, other: &u16) -> bool {
        self.parts[0] == *other
    }
}

impl PartialEq<Vec<u16>> for Param {
    fn eq(&self, other: &Vec<u16>) -> bool {
        self.parts[..=self.cur_part] == other[..]
    }
}

#[cfg(test)]
mod tests;
