use super::{
    AnsiMode, CtcOp, DecMode, EdScope, ElScope, Function, Parser, SgrOp, SgrOps, State, TbcScope,
    XtwinopsOp,
};
use crate::charset::Charset;
use crate::color::Color;

impl Parser {
    pub(crate) fn dump(&self) -> String {
        use State::*;

        let mut seq = String::new();

        match self.state {
            Ground => {}
            Escape => seq.push('\u{1b}'),
            EscapeIntermediate => push_dump_state(&mut seq, '\u{1b}', self.intermediate, None),
            CsiEntry => seq.push('\u{9b}'),
            CsiParam => {
                let params = self.params[..=self.cur_param]
                    .iter()
                    .map(|param| param.to_string())
                    .collect::<Vec<_>>()
                    .join(";");
                push_dump_state(&mut seq, '\u{9b}', self.intermediate, Some(&params));
            }
            CsiIntermediate => push_dump_state(&mut seq, '\u{9b}', self.intermediate, None),
            CsiIgnore => seq.push_str("\u{9b}\u{3a}"),
            DcsEntry => seq.push('\u{90}'),
            DcsIntermediate => push_dump_state(&mut seq, '\u{90}', self.intermediate, None),
            DcsParam => {
                let params = self.params[..=self.cur_param]
                    .iter()
                    .map(|param| param.to_string())
                    .collect::<Vec<_>>()
                    .join(";");
                push_dump_state(&mut seq, '\u{90}', self.intermediate, Some(&params));
            }
            DcsPassthrough => {
                push_dump_state(&mut seq, '\u{90}', self.intermediate, Some("\u{40}"))
            }
            DcsIgnore => seq.push_str("\u{90}\u{3a}"),
            OscString => seq.push('\u{9d}'),
            SosPmApcString => seq.push('\u{98}'),
        }

        seq
    }
}

pub(crate) fn dump(funs: &[Function]) -> String {
    let mut seq = String::new();

    for fun in funs {
        dump_function(&mut seq, fun);
    }

    seq
}

pub(crate) fn dump_sgr_color(color: Color, base: u8) -> String {
    match color {
        Color::Indexed(c) if c < 8 => (base + c).to_string(),
        Color::Indexed(c) if c < 16 => (base + 52 + c).to_string(),
        Color::Indexed(c) => format!("{}:5:{}", base + 8, c),
        Color::RGB(c) => format!("{}:2:{}:{}:{}", base + 8, c.r, c.g, c.b),
    }
}

fn push_dump_state(
    seq: &mut String,
    prefix: char,
    intermediate: Option<char>,
    suffix: Option<&str>,
) {
    seq.push(prefix);

    if let Some(intermediate) = intermediate {
        seq.push(intermediate);
    }

    if let Some(suffix) = suffix {
        seq.push_str(suffix);
    }
}

fn dump_function(seq: &mut String, fun: &Function) {
    use CtcOp::*;
    use EdScope::*;
    use ElScope::*;
    use Function::*;
    use TbcScope::*;
    use XtwinopsOp::*;

    match fun {
        Bs => seq.push('\u{08}'),
        Cbt(n) => push_csi(seq, None, &[n.to_string()], 'Z'),
        Cha(n) => push_csi(seq, None, &[n.to_string()], 'G'),
        Cht(n) => push_csi(seq, None, &[n.to_string()], 'I'),
        Cnl(n) => push_csi(seq, None, &[n.to_string()], 'E'),
        Cpl(n) => push_csi(seq, None, &[n.to_string()], 'F'),
        Cr => seq.push('\r'),
        Ctc(op) => {
            let param = match op {
                Set => 0,
                ClearCurrentColumn => 2,
                ClearAll => 5,
            };
            push_csi(seq, None, &[param.to_string()], 'W');
        }
        Cub(n) => push_csi(seq, None, &[n.to_string()], 'D'),
        Cud(n) => push_csi(seq, None, &[n.to_string()], 'B'),
        Cuf(n) => push_csi(seq, None, &[n.to_string()], 'C'),
        Cup(row, col) => push_csi(seq, None, &[row.to_string(), col.to_string()], 'H'),
        Cuu(n) => push_csi(seq, None, &[n.to_string()], 'A'),
        Dch(n) => push_csi(seq, None, &[n.to_string()], 'P'),
        Decaln => push_esc(seq, Some('#'), '8'),
        Decrc => push_esc(seq, None, '8'),
        Decrst(modes) => dump_dec_modes(seq, modes.as_slice(), 'l'),
        Decsc => push_esc(seq, None, '7'),
        Decset(modes) => dump_dec_modes(seq, modes.as_slice(), 'h'),
        Decstbm(top, bottom) => push_csi(seq, None, &[top.to_string(), bottom.to_string()], 'r'),
        Decstr => push_csi(seq, Some('!'), &[], 'p'),
        Dl(n) => push_csi(seq, None, &[n.to_string()], 'M'),
        Ech(n) => push_csi(seq, None, &[n.to_string()], 'X'),
        Ed(scope) => {
            let param = match scope {
                Below => 0,
                Above => 1,
                EdScope::All => 2,
                SavedLines => 3,
            };
            push_csi(seq, None, &[param.to_string()], 'J');
        }
        El(scope) => {
            let param = match scope {
                ToRight => 0,
                ToLeft => 1,
                ElScope::All => 2,
            };
            push_csi(seq, None, &[param.to_string()], 'K');
        }
        G1d4(charset) => dump_charset(seq, Some(')'), charset),
        Gzd4(charset) => dump_charset(seq, Some('('), charset),
        Ht => seq.push('\t'),
        Hts => push_esc(seq, None, 'H'),
        Ich(n) => push_csi(seq, None, &[n.to_string()], '@'),
        Il(n) => push_csi(seq, None, &[n.to_string()], 'L'),
        Lf => seq.push('\n'),
        Nel => push_esc(seq, None, 'E'),
        Print(ch) => seq.push(*ch),
        Rep(n) => push_csi(seq, None, &[n.to_string()], 'b'),
        Ri => push_esc(seq, None, 'M'),
        Ris => push_esc(seq, None, 'c'),
        Rm(modes) => dump_ansi_modes(seq, modes.as_slice(), 'l'),
        Scorc => push_csi(seq, None, &[], 'u'),
        Scosc => push_csi(seq, None, &[], 's'),
        Sd(n) => push_csi(seq, None, &[n.to_string()], 'T'),
        Sgr(ops) => dump_sgr(seq, ops),
        Si => seq.push('\u{0f}'),
        Sm(modes) => dump_ansi_modes(seq, modes.as_slice(), 'h'),
        So => seq.push('\u{0e}'),
        Su(n) => push_csi(seq, None, &[n.to_string()], 'S'),
        Tbc(scope) => {
            let param = match scope {
                CurrentColumn => 0,
                TbcScope::All => 3,
            };
            push_csi(seq, None, &[param.to_string()], 'g');
        }
        Vpa(n) => push_csi(seq, None, &[n.to_string()], 'd'),
        Vpr(n) => push_csi(seq, None, &[n.to_string()], 'e'),
        Xtwinops(Resize(cols, rows)) => {
            push_csi(
                seq,
                None,
                &["8".to_owned(), rows.to_string(), cols.to_string()],
                't',
            );
        }
    }
}

fn dump_charset(seq: &mut String, intermediate: Option<char>, charset: &Charset) {
    push_esc(
        seq,
        intermediate,
        match charset {
            Charset::Drawing => '0',
            Charset::Ascii => 'B',
        },
    );
}

fn dump_dec_modes(seq: &mut String, modes: &[DecMode], final_char: char) {
    use DecMode::*;

    let params = modes
        .iter()
        .map(|mode| match mode {
            CursorKeys => 1,
            Origin => 6,
            AutoWrap => 7,
            TextCursorEnable => 25,
            AltScreenBuffer => 1047,
            SaveCursor => 1048,
            SaveCursorAltScreenBuffer => 1049,
        })
        .map(|param| param.to_string())
        .collect::<Vec<_>>();

    push_csi(seq, Some('?'), &params, final_char);
}

fn dump_ansi_modes(seq: &mut String, modes: &[AnsiMode], final_char: char) {
    use AnsiMode::*;

    let params = modes
        .iter()
        .map(|mode| match mode {
            Insert => 4,
            NewLine => 20,
        })
        .map(|param| param.to_string())
        .collect::<Vec<_>>();

    push_csi(seq, None, &params, final_char);
}

fn dump_sgr(seq: &mut String, ops: &SgrOps) {
    use SgrOp::*;

    if ops.is_empty() {
        seq.push_str("\x1b[38;2m");
        return;
    }

    let params = ops
        .as_slice()
        .iter()
        .map(|op| match op {
            Reset => "0".to_owned(),
            SetBoldIntensity => "1".to_owned(),
            SetFaintIntensity => "2".to_owned(),
            SetItalic => "3".to_owned(),
            SetUnderline => "4".to_owned(),
            SetBlink => "5".to_owned(),
            SetInverse => "7".to_owned(),
            SetStrikethrough => "9".to_owned(),
            ResetIntensity => "22".to_owned(),
            ResetItalic => "23".to_owned(),
            ResetUnderline => "24".to_owned(),
            ResetBlink => "25".to_owned(),
            ResetInverse => "27".to_owned(),
            ResetStrikethrough => "29".to_owned(),
            SetForegroundColor(color) => dump_sgr_color(*color, 30),
            ResetForegroundColor => "39".to_owned(),
            SetBackgroundColor(color) => dump_sgr_color(*color, 40),
            ResetBackgroundColor => "49".to_owned(),
        })
        .collect::<Vec<_>>();

    push_csi(seq, None, &params, 'm');
}

fn push_esc(seq: &mut String, intermediate: Option<char>, final_char: char) {
    seq.push('\u{1b}');

    if let Some(intermediate) = intermediate {
        seq.push(intermediate);
    }

    seq.push(final_char);
}

fn push_csi(seq: &mut String, intermediate: Option<char>, params: &[String], final_char: char) {
    seq.push('\u{1b}');
    seq.push('[');

    if let Some(intermediate) = intermediate {
        seq.push(intermediate);
    }

    if let Some((first, rest)) = params.split_first() {
        seq.push_str(first);

        for param in rest {
            seq.push(';');
            seq.push_str(param);
        }
    }

    seq.push(final_char);
}
