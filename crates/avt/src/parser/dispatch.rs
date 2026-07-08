use super::{
    AnsiMode, AnsiModes, CtcOp, DecMode, DecModes, EdScope, ElScope, Function, Param, Parser,
    SgrOp, SgrOps, State, TbcScope, XtwinopsOp, PARAMS_LEN,
};
use crate::charset::Charset;
use crate::color::Color;

impl Parser {
    pub(super) fn execute(&mut self, input: char) -> Option<Function> {
        use Function::*;

        match input {
            '\u{08}' => Some(Bs),
            '\u{09}' => Some(Ht),
            '\u{0a}' => Some(Lf),
            '\u{0b}' => Some(Lf),
            '\u{0c}' => Some(Lf),
            '\u{0d}' => Some(Cr),
            '\u{0e}' => Some(So),
            '\u{0f}' => Some(Si),
            '\u{84}' => Some(Lf),
            '\u{85}' => Some(Nel),
            '\u{88}' => Some(Hts),
            '\u{8d}' => Some(Ri),
            _ => None,
        }
    }

    pub(super) fn clear(&mut self) {
        for p in &mut self.params[..=self.cur_param] {
            p.clear();
        }

        self.cur_param = 0;
        self.intermediate = None;
    }

    pub(super) fn collect(&mut self, input: char) {
        self.intermediate = Some(input);
    }

    pub(super) fn param(&mut self, input: char) {
        if input == ';' {
            self.cur_param += 1;

            if self.cur_param == PARAMS_LEN {
                self.cur_param = PARAMS_LEN - 1;
            }
        } else if input == ':' {
            self.params[self.cur_param].add_part();
        } else {
            self.params[self.cur_param].add_digit((input as u8) - 0x30);
        }
    }

    pub(super) fn esc_dispatch(&mut self, input: char) -> Option<Function> {
        use Function::*;

        match (self.intermediate, input) {
            (None, c) if ('@'..='_').contains(&c) => self.execute(((input as u8) + 0x40) as char),

            (None, '7') => Some(Decsc),

            (None, '8') => Some(Decrc),

            (None, 'c') => {
                self.state = State::Ground;
                Some(Ris)
            }

            (Some('#'), '8') => Some(Decaln),

            (Some('('), '0') => Some(Gzd4(Charset::Drawing)),

            (Some('('), _) => Some(Gzd4(Charset::Ascii)),

            (Some(')'), '0') => Some(G1d4(Charset::Drawing)),

            (Some(')'), _) => Some(G1d4(Charset::Ascii)),

            _ => None,
        }
    }

    pub(super) fn csi_dispatch(&mut self, input: char) -> Option<Function> {
        use Function::*;

        let ps = &self.params;

        match (self.intermediate, input) {
            (None, '@') => Some(Ich(ps[0].as_u16())),

            (None, 'A') => Some(Cuu(ps[0].as_u16())),

            (None, 'B') => Some(Cud(ps[0].as_u16())),

            (None, 'C') => Some(Cuf(ps[0].as_u16())),

            (None, 'D') => Some(Cub(ps[0].as_u16())),

            (None, 'E') => Some(Cnl(ps[0].as_u16())),

            (None, 'F') => Some(Cpl(ps[0].as_u16())),

            (None, 'G') => Some(Cha(ps[0].as_u16())),

            (None, 'H') => Some(Cup(ps[0].as_u16(), ps[1].as_u16())),

            (None, 'I') => Some(Cht(ps[0].as_u16())),

            (None, 'J') => match ps[0].as_u16() {
                0 => Some(Ed(EdScope::Below)),
                1 => Some(Ed(EdScope::Above)),
                2 => Some(Ed(EdScope::All)),
                3 => Some(Ed(EdScope::SavedLines)),
                _ => None,
            },

            (None, 'K') => match ps[0].as_u16() {
                0 => Some(El(ElScope::ToRight)),
                1 => Some(El(ElScope::ToLeft)),
                2 => Some(El(ElScope::All)),
                _ => None,
            },

            (None, 'L') => Some(Il(ps[0].as_u16())),

            (None, 'M') => Some(Dl(ps[0].as_u16())),

            (None, 'P') => Some(Dch(ps[0].as_u16())),

            (None, 'S') => Some(Su(ps[0].as_u16())),

            (None, 'T') => Some(Sd(ps[0].as_u16())),

            (None, 'W') => match ps[0].as_u16() {
                0 => Some(Ctc(CtcOp::Set)),
                2 => Some(Ctc(CtcOp::ClearCurrentColumn)),
                5 => Some(Ctc(CtcOp::ClearAll)),
                _ => None,
            },

            (None, 'X') => Some(Ech(ps[0].as_u16())),

            (None, 'Z') => Some(Cbt(ps[0].as_u16())),

            (None, '`') => Some(Cha(ps[0].as_u16())),

            (None, 'a') => Some(Cuf(ps[0].as_u16())),

            (None, 'b') => Some(Rep(ps[0].as_u16())),

            (None, 'd') => Some(Vpa(ps[0].as_u16())),

            (None, 'e') => Some(Vpr(ps[0].as_u16())),

            (None, 'f') => Some(Cup(ps[0].as_u16(), ps[1].as_u16())),

            (None, 'g') => match ps[0].as_u16() {
                0 => Some(Tbc(TbcScope::CurrentColumn)),
                3 => Some(Tbc(TbcScope::All)),
                _ => None,
            },

            (None, 'h') => Some(Sm(AnsiModes::collect(
                ps[..=self.cur_param].iter().filter_map(ansi_mode),
            ))),

            (None, 'l') => Some(Rm(AnsiModes::collect(
                ps[..=self.cur_param].iter().filter_map(ansi_mode),
            ))),

            (None, 'm') => Some(Sgr(SgrOps::collect(SgrOpsDecoder {
                ps: &ps[..=self.cur_param],
            }))),

            (None, 'r') => Some(Decstbm(ps[0].as_u16(), ps[1].as_u16())),

            (None, 's') => Some(Scosc),

            (None, 't') => {
                if ps[0].as_u16() == 8 {
                    let rows = ps[1].as_u16();
                    let cols = ps[2].as_u16();

                    Some(Xtwinops(XtwinopsOp::Resize(cols, rows)))
                } else {
                    None
                }
            }

            (None, 'u') => Some(Scorc),

            (Some('!'), 'p') => Some(Decstr),

            (Some('?'), 'h') => Some(Decset(DecModes::collect(
                ps[..=self.cur_param].iter().filter_map(dec_mode),
            ))),

            (Some('?'), 'l') => Some(Decrst(DecModes::collect(
                ps[..=self.cur_param].iter().filter_map(dec_mode),
            ))),

            _ => None,
        }
    }

    pub(super) fn put(&mut self, _input: char) {}

    pub(super) fn osc_put(&mut self, _input: char) {}
}

fn ansi_mode(param: &Param) -> Option<AnsiMode> {
    use AnsiMode::*;

    match param.as_u16() {
        4 => Some(Insert),
        20 => Some(NewLine),
        _ => None,
    }
}

struct SgrOpsDecoder<'a> {
    ps: &'a [Param],
}

impl Iterator for SgrOpsDecoder<'_> {
    type Item = SgrOp;

    fn next(&mut self) -> Option<Self::Item> {
        use SgrOp::*;

        while let Some(param) = self.ps.first() {
            match param.parts() {
                [0] => {
                    self.ps = &self.ps[1..];

                    return Some(Reset);
                }

                [1] => {
                    self.ps = &self.ps[1..];

                    return Some(SetBoldIntensity);
                }

                [2] => {
                    self.ps = &self.ps[1..];

                    return Some(SetFaintIntensity);
                }

                [3] => {
                    self.ps = &self.ps[1..];

                    return Some(SetItalic);
                }

                [4] => {
                    self.ps = &self.ps[1..];

                    return Some(SetUnderline);
                }

                [5] => {
                    self.ps = &self.ps[1..];

                    return Some(SetBlink);
                }

                [7] => {
                    self.ps = &self.ps[1..];

                    return Some(SetInverse);
                }

                [9] => {
                    self.ps = &self.ps[1..];

                    return Some(SetStrikethrough);
                }

                [21] | [22] => {
                    self.ps = &self.ps[1..];

                    return Some(ResetIntensity);
                }

                [23] => {
                    self.ps = &self.ps[1..];

                    return Some(ResetItalic);
                }

                [24] => {
                    self.ps = &self.ps[1..];

                    return Some(ResetUnderline);
                }

                [25] => {
                    self.ps = &self.ps[1..];

                    return Some(ResetBlink);
                }

                [27] => {
                    self.ps = &self.ps[1..];

                    return Some(ResetInverse);
                }

                [29] => {
                    self.ps = &self.ps[1..];

                    return Some(ResetStrikethrough);
                }

                [param] if *param >= 30 && *param <= 37 => {
                    let color = Color::Indexed((param - 30) as u8);
                    self.ps = &self.ps[1..];

                    return Some(SetForegroundColor(color));
                }

                [38, 2, r, g, b] | [38, 2, _, r, g, b] => {
                    self.ps = &self.ps[1..];

                    return Some(SetForegroundColor(Color::rgb(*r as u8, *g as u8, *b as u8)));
                }

                [38, 5, idx] => {
                    let color = Color::Indexed(*idx as u8);
                    self.ps = &self.ps[1..];

                    return Some(SetForegroundColor(color));
                }

                [38] => match self.ps.get(1).map(|p| p.parts()) {
                    None => {
                        self.ps = &self.ps[1..];
                    }

                    Some([2]) => {
                        if let Some(b) = self.ps.get(4) {
                            let r = self.ps.get(2).unwrap().as_u16();
                            let g = self.ps.get(3).unwrap().as_u16();
                            let b = b.as_u16();
                            let color = Color::rgb(r as u8, g as u8, b as u8);
                            self.ps = &self.ps[5..];

                            return Some(SetForegroundColor(color));
                        } else {
                            self.ps = &self.ps[2..];
                        }
                    }

                    Some([5]) => {
                        if let Some(idx) = self.ps.get(2) {
                            let idx = idx.as_u16();
                            let color = Color::Indexed(idx as u8);
                            self.ps = &self.ps[3..];

                            return Some(SetForegroundColor(color));
                        } else {
                            self.ps = &self.ps[2..];
                        }
                    }

                    Some(_) => {
                        self.ps = &self.ps[1..];
                    }
                },

                [39] => {
                    self.ps = &self.ps[1..];

                    return Some(ResetForegroundColor);
                }

                [param] if *param >= 40 && *param <= 47 => {
                    let color = Color::Indexed((param - 40) as u8);
                    self.ps = &self.ps[1..];

                    return Some(SetBackgroundColor(color));
                }

                [48, 2, r, g, b] | [48, 2, _, r, g, b] => {
                    let color = Color::rgb(*r as u8, *g as u8, *b as u8);
                    self.ps = &self.ps[1..];

                    return Some(SetBackgroundColor(color));
                }

                [48, 5, idx] => {
                    let color = Color::Indexed(*idx as u8);
                    self.ps = &self.ps[1..];

                    return Some(SetBackgroundColor(color));
                }

                [48] => match self.ps.get(1).map(|p| p.parts()) {
                    None => {
                        self.ps = &self.ps[1..];
                    }

                    Some([2]) => {
                        if let Some(b) = self.ps.get(4) {
                            let r = self.ps.get(2).unwrap().as_u16();
                            let g = self.ps.get(3).unwrap().as_u16();
                            let b = b.as_u16();
                            let color = Color::rgb(r as u8, g as u8, b as u8);
                            self.ps = &self.ps[5..];

                            return Some(SetBackgroundColor(color));
                        } else {
                            self.ps = &self.ps[2..];
                        }
                    }

                    Some([5]) => {
                        if let Some(idx) = self.ps.get(2) {
                            let idx = idx.as_u16();
                            let color = Color::Indexed(idx as u8);
                            self.ps = &self.ps[3..];

                            return Some(SetBackgroundColor(color));
                        } else {
                            self.ps = &self.ps[2..];
                        }
                    }

                    Some(_) => {
                        self.ps = &self.ps[1..];
                    }
                },

                [49] => {
                    self.ps = &self.ps[1..];

                    return Some(ResetBackgroundColor);
                }

                [param] if *param >= 90 && *param <= 97 => {
                    let color = Color::Indexed((param - 90 + 8) as u8);
                    self.ps = &self.ps[1..];

                    return Some(SetForegroundColor(color));
                }

                [param] if *param >= 100 && *param <= 107 => {
                    let color = Color::Indexed((param - 100 + 8) as u8);
                    self.ps = &self.ps[1..];

                    return Some(SetBackgroundColor(color));
                }

                _ => {
                    self.ps = &self.ps[1..];
                }
            }
        }

        None
    }
}

fn dec_mode(param: &Param) -> Option<DecMode> {
    use DecMode::*;

    match param.as_u16() {
        1 => Some(CursorKeys),
        6 => Some(Origin),
        7 => Some(AutoWrap),
        25 => Some(TextCursorEnable),
        47 => Some(AltScreenBuffer), // legacy variant of 1047
        1047 => Some(AltScreenBuffer),
        1048 => Some(SaveCursor),
        1049 => Some(SaveCursorAltScreenBuffer),
        _ => None,
    }
}
