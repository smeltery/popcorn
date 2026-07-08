use super::AnsiMode;
use super::AnsiModes;
use super::CtcOp;
use super::DecMode;
use super::DecModes;
use super::EdScope;
use super::ElScope;
use super::Function;
use super::Function::*;
use super::Parser;
use super::SgrOp::*;
use super::SgrOps;
use super::State;
use super::TbcScope;
use super::XtwinopsOp;
use crate::charset::Charset;
use crate::color::Color;
use proptest::prelude::*;

fn parse(s: &str) -> Vec<Function> {
    let mut parser = Parser::new();

    s.chars().filter_map(|ch| parser.feed(ch)).collect()
}

fn emit(parser: &mut Parser, input: &[char]) -> Vec<Function> {
    input.iter().filter_map(|ch| parser.feed(*ch)).collect()
}

fn feed(parser: &mut Parser, s: &str) {
    for ch in s.chars() {
        assert_eq!(parser.feed(ch), None);
    }
}

fn sgr_ops<const N: usize>(ops: [super::SgrOp; N]) -> SgrOps {
    SgrOps::from(&ops[..])
}

fn ansi_modes<const N: usize>(modes: [AnsiMode; N]) -> AnsiModes {
    AnsiModes::from(&modes[..])
}

fn dec_modes<const N: usize>(modes: [DecMode; N]) -> DecModes {
    DecModes::from(&modes[..])
}

fn assert_dump(input: &str, state: State, dump: &str) {
    let mut parser = Parser::new();

    feed(&mut parser, input);

    assert_eq!(parser.state, state);
    assert_eq!(parser.dump(), dump);
}

fn gen_parser_char() -> impl Strategy<Value = char> {
    prop_oneof![
        prop::sample::select(vec![
            '\x1b', '\x18', '\x1a', '\u{9b}', '\u{9c}', '\u{9d}', '\u{90}', '\u{98}', '\u{9e}',
            '\u{9f}', '[', ']', 'P', 'X', '^', '_', '?', '!', ';', ':', ' ', '#', '(', ')', '@',
            'A', 'B', 'C', 'D', 'H', 'J', 'K', 'L', 'M', 'P', 'S', 'T', 'W', 'X', 'Z', '`', 'a',
            'b', 'd', 'e', 'f', 'g', 'h', 'l', 'm', 'p', 'r', 's', 't', 'u', '0', '1', '2', '3',
            '4', '5', '6', '7', '8', '9', '\x08', '\x09', '\x0a', '\x0d', '\x0e', '\x0f',
        ]),
        (0x20u8..=0x7eu8).prop_map(|b| b as char),
        prop::sample::select(vec!['日', '▒', 'ハ']),
    ]
}

fn gen_parser_input(max_len: usize) -> impl Strategy<Value = Vec<char>> {
    prop::collection::vec(gen_parser_char(), 0..=max_len)
}

fn gen_printable_text(max_len: usize) -> impl Strategy<Value = Vec<char>> {
    prop::collection::vec(
        prop_oneof![
            (0x20u8..=0x7eu8).prop_map(|b| b as char),
            prop::sample::select(vec!['日', '▒', 'ハ']),
        ],
        0..=max_len,
    )
}

fn gen_non_ground_prefix() -> impl Strategy<Value = Vec<char>> {
    prop_oneof![
        Just("\x1b".chars().collect()),
        Just("\x1b[".chars().collect()),
        Just("\x1b[12".chars().collect()),
        Just("\x1b[1;".chars().collect()),
        Just("\x1b[?".chars().collect()),
        Just("\x1b[ ".chars().collect()),
        Just("\x1b[:".chars().collect()),
        Just("\x1b(".chars().collect()),
        Just("\x1b]".chars().collect()),
        Just("\x1b]title".chars().collect()),
        Just("\x1bP".chars().collect()),
        Just("\x1bP1;2".chars().collect()),
        Just("\x1bP:".chars().collect()),
        Just("\x1bX".chars().collect()),
        Just("\x1bXabc".chars().collect()),
        Just("\u{9b}".chars().collect()),
        Just("\u{9b}12".chars().collect()),
        Just("\u{9d}title".chars().collect()),
        Just("\u{90}".chars().collect()),
        Just("\u{90}1;2".chars().collect()),
        Just("\u{98}".chars().collect()),
        Just("\u{98}abc".chars().collect()),
    ]
}

#[test]
fn parse_c0() {
    assert_eq!(parse("\x08"), [Bs]);
    assert_eq!(parse("\x0a"), [Lf]);
    assert_eq!(parse("\x0d"), [Cr]);
    assert_eq!(parse("\x0e"), [So]);
    assert_eq!(parse("\x0f"), [Si]);
}

#[test]
fn parse_c1() {
    assert_eq!(parse("\u{84}"), [Lf]);
    assert_eq!(parse("\u{85}"), [Nel]);
    assert_eq!(parse("\u{88}"), [Hts]);
    assert_eq!(parse("\u{8d}"), [Ri]);
}

#[test]
fn parse_esc_seq() {
    assert_eq!(parse("\x1b7"), [Decsc]);
    assert_eq!(parse("\x1b8"), [Decrc]);
    assert_eq!(parse("\x1bc"), [Ris]);
    assert_eq!(parse("\x1bM"), [Ri]);
    assert_eq!(parse("\x1b#8"), [Decaln]);
    assert_eq!(parse("\x1b(0"), [Gzd4(Charset::Drawing)]);
    assert_eq!(parse("\x1b(B"), [Gzd4(Charset::Ascii)]);
    assert_eq!(parse("\x1b)0"), [G1d4(Charset::Drawing)]);
    assert_eq!(parse("\x1b)B"), [G1d4(Charset::Ascii)]);
}

#[test]
fn parse_csi_seq() {
    // Cursor movement and positioning.
    assert_eq!(parse("\x1b[A"), [Cuu(0)]);
    assert_eq!(parse("\x1b[B"), [Cud(0)]);
    assert_eq!(parse("\x1b[2B"), [Cud(2)]);
    assert_eq!(parse("\x1b[C"), [Cuf(0)]);
    assert_eq!(parse("\x1b[3C"), [Cuf(3)]);
    assert_eq!(parse("\x1b[D"), [Cub(0)]);
    assert_eq!(parse("\x1b[4D"), [Cub(4)]);
    assert_eq!(parse("\x1b[5E"), [Cnl(5)]);
    assert_eq!(parse("\x1b[6F"), [Cpl(6)]);
    assert_eq!(parse("\x1b[G"), [Cha(0)]);
    assert_eq!(parse("\x1b[7G"), [Cha(7)]);
    assert_eq!(parse("\x1b[H"), [Cup(0, 0)]);
    assert_eq!(parse("\x1b[3;4H"), [Cup(3, 4)]);
    assert_eq!(parse("\u{9b}3;4H"), [Cup(3, 4)]);
    assert_eq!(parse("\x1b[8I"), [Cht(8)]);
    assert_eq!(parse("\x1b[2Z"), [Cbt(2)]);
    assert_eq!(parse("\x1b[`"), [Cha(0)]);
    assert_eq!(parse("\x1b[9`"), [Cha(9)]);
    assert_eq!(parse("\x1b[10a"), [Cuf(10)]);
    assert_eq!(parse("\x1b[11b"), [Rep(11)]);
    assert_eq!(parse("\x1b[12d"), [Vpa(12)]);
    assert_eq!(parse("\x1b[13e"), [Vpr(13)]);
    assert_eq!(parse("\x1b[f"), [Cup(0, 0)]);
    assert_eq!(parse("\x1b[14;15f"), [Cup(14, 15)]);

    // Erase, insert/delete, scrolling, and tab control.
    assert_eq!(parse("\x1b[@"), [Ich(0)]);
    assert_eq!(parse("\x1b[J"), [Ed(EdScope::Below)]);
    assert_eq!(parse("\x1b[0J"), [Ed(EdScope::Below)]);
    assert_eq!(parse("\x1b[1J"), [Ed(EdScope::Above)]);
    assert_eq!(parse("\x1b[2J"), [Ed(EdScope::All)]);
    assert_eq!(parse("\u{9b}2J"), [Ed(EdScope::All)]);
    assert_eq!(parse("\x1b[3J"), [Ed(EdScope::SavedLines)]);
    assert_eq!(parse("\x1b[K"), [El(ElScope::ToRight)]);
    assert_eq!(parse("\x1b[0K"), [El(ElScope::ToRight)]);
    assert_eq!(parse("\x1b[1K"), [El(ElScope::ToLeft)]);
    assert_eq!(parse("\x1b[2K"), [El(ElScope::All)]);
    assert_eq!(parse("\x1b[16L"), [Il(16)]);
    assert_eq!(parse("\x1b[17M"), [Dl(17)]);
    assert_eq!(parse("\x1b[18P"), [Dch(18)]);
    assert_eq!(parse("\x1b[19S"), [Su(19)]);
    assert_eq!(parse("\x1b[20T"), [Sd(20)]);
    assert_eq!(parse("\x1b[W"), [Ctc(CtcOp::Set)]);
    assert_eq!(parse("\x1b[2W"), [Ctc(CtcOp::ClearCurrentColumn)]);
    assert_eq!(parse("\x1b[5W"), [Ctc(CtcOp::ClearAll)]);
    assert_eq!(parse("\x1b[21X"), [Ech(21)]);
    assert_eq!(parse("\x1b[g"), [Tbc(TbcScope::CurrentColumn)]);
    assert_eq!(parse("\x1b[3g"), [Tbc(TbcScope::All)]);

    // ANSI mode setting and generic CSI operations.
    assert_eq!(
        parse("\x1b[4;20h"),
        [Sm(ansi_modes([AnsiMode::Insert, AnsiMode::NewLine]))]
    );
    assert_eq!(
        parse("\x1b[4;20l"),
        [Rm(ansi_modes([AnsiMode::Insert, AnsiMode::NewLine]))]
    );
    assert_eq!(parse("\x1b[m"), [Sgr(sgr_ops([Reset]))]);
    assert_eq!(parse("\x1b[2;5r"), [Decstbm(2, 5)]);
    assert_eq!(
        parse("\x1b[8;24;80t"),
        [Xtwinops(XtwinopsOp::Resize(80, 24))]
    );
    assert_eq!(parse("\x1b[s"), [Scosc]);
    assert_eq!(parse("\x1b[u"), [Scorc]);
    assert_eq!(parse("\x1b[!p"), [Decstr]);

    // DEC private modes.
    assert_eq!(parse("\x1b[?7h"), [Decset(dec_modes([DecMode::AutoWrap]))]);
    assert_eq!(parse("\u{9b}?7h"), [Decset(dec_modes([DecMode::AutoWrap]))]);
    assert_eq!(
        parse("\x1b[?6;1047h"),
        [Decset(dec_modes([
            DecMode::Origin,
            DecMode::AltScreenBuffer
        ]))]
    );
    assert_eq!(
        parse("\x1b[?47h"),
        [Decset(dec_modes([DecMode::AltScreenBuffer]))]
    );
    assert_eq!(
        parse("\x1b[?1049h"),
        [Decset(dec_modes([DecMode::SaveCursorAltScreenBuffer]))]
    );
    assert_eq!(
        parse("\u{9b}?1049h"),
        [Decset(dec_modes([DecMode::SaveCursorAltScreenBuffer]))]
    );
    assert_eq!(parse("\x1b[?7l"), [Decrst(dec_modes([DecMode::AutoWrap]))]);
    assert_eq!(parse("\u{9b}?7l"), [Decrst(dec_modes([DecMode::AutoWrap]))]);
    assert_eq!(
        parse("\x1b[?47l"),
        [Decrst(dec_modes([DecMode::AltScreenBuffer]))]
    );
    assert_eq!(
        parse("\x1b[?6;1049l"),
        [Decrst(dec_modes([
            DecMode::Origin,
            DecMode::SaveCursorAltScreenBuffer,
        ]))]
    );
    assert_eq!(
        parse("\u{9b}?6;1049l"),
        [Decrst(dec_modes([
            DecMode::Origin,
            DecMode::SaveCursorAltScreenBuffer,
        ]))]
    );
}

#[test]
fn parse_partial_and_interrupted_seq() {
    let mut parser = Parser::new();

    assert_eq!(parser.feed('\x1b'), None);
    assert_eq!(parser.feed('['), None);
    assert_eq!(parser.feed('3'), None);
    assert_eq!(parser.feed(';'), None);
    assert_eq!(parser.feed('4'), None);
    assert_eq!(parser.feed('H'), Some(Cup(3, 4)));

    assert_eq!(parser.feed('\x1b'), None);
    assert_eq!(parser.feed('['), None);
    assert_eq!(parser.feed('3'), None);
    assert_eq!(parser.feed('\x1b'), None);
    assert_eq!(parser.feed('M'), Some(Ri));

    feed(&mut parser, "\x1b");
    assert_eq!(parser.state, State::Escape);
    assert_eq!(parser.feed('\u{18}'), None);
    assert_eq!(parser.state, State::Ground);
    assert_eq!(parser.feed('A'), Some(Print('A')));

    feed(&mut parser, "\x1b[12");
    assert_eq!(parser.state, State::CsiParam);
    assert_eq!(parser.feed('\u{1a}'), None);
    assert_eq!(parser.state, State::Ground);
    assert_eq!(parser.feed('B'), Some(Print('B')));

    feed(&mut parser, "\x1b]title");
    assert_eq!(parser.state, State::OscString);
    assert_eq!(parser.feed('\u{18}'), None);
    assert_eq!(parser.state, State::Ground);
    assert_eq!(parser.feed('C'), Some(Print('C')));

    feed(&mut parser, "\x1bP1;2");
    assert_eq!(parser.state, State::DcsParam);
    assert_eq!(parser.feed('\u{1a}'), None);
    assert_eq!(parser.state, State::Ground);
    assert_eq!(parser.feed('D'), Some(Print('D')));
}

#[test]
fn ignore_unsupported_seq() {
    assert_eq!(parse("\x1b[4q"), []);
    assert_eq!(parse("\x1b[9W"), []);
    assert_eq!(parse("\x1b[?9999h"), [Decset(dec_modes([]))]);
    assert_eq!(parse("\x1b[:m"), []);
    assert_eq!(parse("\x1b[1?m"), []);
    assert_eq!(parse("\x1b[ 1H"), []);
    assert_eq!(parse("\x1b[ 1m"), []);
    assert_eq!(parse("\x1b[1 q"), []);
    assert_eq!(parse("\x1b[38;2m"), [Sgr(sgr_ops([]))]);
    assert_eq!(parse("\x1b[48;5m"), [Sgr(sgr_ops([]))]);
}

#[test]
fn parse_sgr_seq() {
    assert_eq!(
        parse("\x1b[;1;m"),
        [Sgr(sgr_ops([Reset, SetBoldIntensity, Reset]))]
    );

    assert_eq!(parse("\x1b[1m"), [Sgr(sgr_ops([SetBoldIntensity]))]);
    assert_eq!(parse("\x1b[2m"), [Sgr(sgr_ops([SetFaintIntensity]))]);
    assert_eq!(parse("\x1b[3m"), [Sgr(sgr_ops([SetItalic]))]);
    assert_eq!(parse("\x1b[4m"), [Sgr(sgr_ops([SetUnderline]))]);
    assert_eq!(parse("\x1b[5m"), [Sgr(sgr_ops([SetBlink]))]);
    assert_eq!(parse("\x1b[7m"), [Sgr(sgr_ops([SetInverse]))]);
    assert_eq!(parse("\x1b[9m"), [Sgr(sgr_ops([SetStrikethrough]))]);
    assert_eq!(parse("\x1b[21m"), [Sgr(sgr_ops([ResetIntensity]))]);
    assert_eq!(parse("\x1b[22m"), [Sgr(sgr_ops([ResetIntensity]))]);
    assert_eq!(parse("\x1b[23m"), [Sgr(sgr_ops([ResetItalic]))]);
    assert_eq!(parse("\x1b[24m"), [Sgr(sgr_ops([ResetUnderline]))]);
    assert_eq!(parse("\x1b[25m"), [Sgr(sgr_ops([ResetBlink]))]);
    assert_eq!(parse("\x1b[27m"), [Sgr(sgr_ops([ResetInverse]))]);
    assert_eq!(parse("\x1b[29m"), [Sgr(sgr_ops([ResetStrikethrough]))]);

    assert_eq!(
        parse("\x1b[31m"),
        [Sgr(sgr_ops([SetForegroundColor(Color::Indexed(1))]))]
    );

    assert_eq!(
        parse("\x1b[38:2:1:2:3m"),
        [Sgr(sgr_ops([SetForegroundColor(Color::rgb(1, 2, 3))]))]
    );

    assert_eq!(
        parse("\x1b[38:2::1:2:3m"),
        [Sgr(sgr_ops([SetForegroundColor(Color::rgb(1, 2, 3))]))]
    );

    assert_eq!(
        parse("\x1b[38:5:88m"),
        [Sgr(sgr_ops([SetForegroundColor(Color::Indexed(88))]))]
    );

    assert_eq!(parse("\x1b[39m"), [Sgr(sgr_ops([ResetForegroundColor]))]);

    assert_eq!(
        parse("\x1b[41m"),
        [Sgr(sgr_ops([SetBackgroundColor(Color::Indexed(1))]))]
    );

    assert_eq!(
        parse("\x1b[91m"),
        [Sgr(sgr_ops([SetForegroundColor(Color::Indexed(9))]))]
    );

    assert_eq!(
        parse("\x1b[48:2:1:2:3m"),
        [Sgr(sgr_ops([SetBackgroundColor(Color::rgb(1, 2, 3))]))]
    );

    assert_eq!(
        parse("\x1b[48:2::1:2:3m"),
        [Sgr(sgr_ops([SetBackgroundColor(Color::rgb(1, 2, 3))]))]
    );

    assert_eq!(
        parse("\x1b[48:5:99m"),
        [Sgr(sgr_ops([SetBackgroundColor(Color::Indexed(99))]))]
    );

    assert_eq!(parse("\x1b[49m"), [Sgr(sgr_ops([ResetBackgroundColor]))]);

    assert_eq!(
        parse("\x1b[104m"),
        [Sgr(sgr_ops([SetBackgroundColor(Color::Indexed(12))]))]
    );

    // legacy syntax for 24-bit color, within a larger sequence
    assert_eq!(
        parse("\x1b[1;38;2;1;2;3;48;2;1;2;3;0m"),
        [Sgr(sgr_ops([
            SetBoldIntensity,
            SetForegroundColor(Color::rgb(1, 2, 3)),
            SetBackgroundColor(Color::rgb(1, 2, 3)),
            Reset,
        ]))]
    );

    // legacy syntax for 8-bit color, within a larger sequence
    assert_eq!(
        parse("\x1b[1;38;5;88;48;5;99;0m"),
        [Sgr(sgr_ops([
            SetBoldIntensity,
            SetForegroundColor(Color::Indexed(88)),
            SetBackgroundColor(Color::Indexed(99)),
            Reset,
        ]))]
    );
}

#[test]
fn parse_string_seq() {
    assert_eq!(parse("\x1b]title\x07A"), [Print('A')]);
    assert_eq!(parse("\x1b]title\x1b\\A"), [Print('A')]);
    assert_eq!(parse("\u{9d}title\u{9c}A"), [Print('A')]);
    assert_eq!(parse("\x1bPabc\u{9c}A"), [Print('A')]);
    assert_eq!(parse("\x1bPabc\x1b\\A"), [Print('A')]);
    assert_eq!(parse("\u{90}abc\u{9c}A"), [Print('A')]);
    assert_eq!(parse("\x1bXabc\u{9c}A"), [Print('A')]);
    assert_eq!(parse("\x1bXabc\x1b\\A"), [Print('A')]);
    assert_eq!(parse("\x1b^abc\u{9c}A"), [Print('A')]);
    assert_eq!(parse("\x1b^abc\x1b\\A"), [Print('A')]);
    assert_eq!(parse("\x1b_abc\u{9c}A"), [Print('A')]);
    assert_eq!(parse("\x1b_abc\x1b\\A"), [Print('A')]);
    assert_eq!(parse("\u{98}abc\u{9c}A"), [Print('A')]);
    assert_eq!(parse("\u{9e}abc\u{9c}A"), [Print('A')]);
    assert_eq!(parse("\u{9f}abc\u{9c}A"), [Print('A')]);
}

#[test]
fn parse_unicode() {
    assert_eq!(parse("日"), [Print('日')]);
    assert_eq!(parse("\x1b[日A"), [Print('A')]);
}

#[test]
fn dump_non_ground_states() {
    assert_dump("\x1b", State::Escape, "\x1b");
    assert_dump("\x1b(", State::EscapeIntermediate, "\x1b(");
    assert_dump("\x1b[", State::CsiEntry, "\u{9b}");
    assert_dump("\x1b[ ", State::CsiIntermediate, "\u{9b} ");
    assert_dump("\x1b[:", State::CsiIgnore, "\u{9b}\u{3a}");
    assert_dump("\x1bP", State::DcsEntry, "\u{90}");
    assert_dump("\x1bP ", State::DcsIntermediate, "\u{90} ");
    assert_dump("\x1bP1;2", State::DcsParam, "\u{90}1;2");
    assert_dump("\x1bPz", State::DcsPassthrough, "\u{90}\u{40}");
    assert_dump("\x1bP:", State::DcsIgnore, "\u{90}\u{3a}");
    assert_dump("\x1b]", State::OscString, "\u{9d}");
    assert_dump("\x1bX", State::SosPmApcString, "\u{98}");
}

#[test]
fn dump() {
    let mut parser = Parser::new();

    for ch in "\x1b[;1;;38:2:1:2:3;".chars() {
        parser.feed(ch);
    }

    assert_eq!(parser.dump(), "\u{9b}0;1;0;38:2:1:2:3;0");
}

#[test]
fn dump_functions_roundtrip() {
    let functions = vec![
        Bs,
        Cbt(2),
        Cha(7),
        Cht(8),
        Cnl(5),
        Cpl(6),
        Cr,
        Ctc(CtcOp::Set),
        Ctc(CtcOp::ClearCurrentColumn),
        Ctc(CtcOp::ClearAll),
        Cub(4),
        Cud(2),
        Cuf(3),
        Cup(3, 4),
        Cuu(1),
        Dch(18),
        Decaln,
        Decrc,
        Decrst(dec_modes([])),
        Decrst(dec_modes([
            DecMode::CursorKeys,
            DecMode::Origin,
            DecMode::AutoWrap,
            DecMode::TextCursorEnable,
            DecMode::AltScreenBuffer,
            DecMode::SaveCursor,
            DecMode::SaveCursorAltScreenBuffer,
        ])),
        Decsc,
        Decset(dec_modes([])),
        Decset(dec_modes([
            DecMode::CursorKeys,
            DecMode::Origin,
            DecMode::AutoWrap,
            DecMode::TextCursorEnable,
            DecMode::AltScreenBuffer,
            DecMode::SaveCursor,
            DecMode::SaveCursorAltScreenBuffer,
        ])),
        Decstbm(2, 5),
        Decstr,
        Dl(17),
        Ech(21),
        Ed(EdScope::Below),
        Ed(EdScope::Above),
        Ed(EdScope::All),
        Ed(EdScope::SavedLines),
        El(ElScope::ToRight),
        El(ElScope::ToLeft),
        El(ElScope::All),
        G1d4(Charset::Drawing),
        G1d4(Charset::Ascii),
        Gzd4(Charset::Drawing),
        Gzd4(Charset::Ascii),
        Ht,
        Hts,
        Ich(16),
        Il(16),
        Lf,
        Nel,
        Print('A'),
        Print('日'),
        Rep(11),
        Ri,
        Ris,
        Rm(ansi_modes([])),
        Rm(ansi_modes([AnsiMode::Insert, AnsiMode::NewLine])),
        Scorc,
        Scosc,
        Sd(20),
        Sgr(sgr_ops([])),
        Sgr(sgr_ops([
            Reset,
            SetBoldIntensity,
            SetFaintIntensity,
            SetItalic,
            SetUnderline,
            SetBlink,
            SetInverse,
            SetStrikethrough,
            ResetIntensity,
            ResetItalic,
            ResetUnderline,
            ResetBlink,
            ResetInverse,
            ResetStrikethrough,
            SetForegroundColor(Color::Indexed(1)),
            ResetForegroundColor,
            SetBackgroundColor(Color::rgb(1, 2, 3)),
            ResetBackgroundColor,
        ])),
        Si,
        Sm(ansi_modes([])),
        Sm(ansi_modes([AnsiMode::Insert, AnsiMode::NewLine])),
        So,
        Su(19),
        Tbc(TbcScope::CurrentColumn),
        Tbc(TbcScope::All),
        Vpa(12),
        Vpr(13),
        Xtwinops(XtwinopsOp::Resize(80, 24)),
    ];

    assert_eq!(parse(&super::dump(&functions)), functions);
}

proptest! {
    #[test]
    fn prop_dump_resume_equivalence(
        input in gen_parser_input(64),
        split in 0usize..65,
    ) {
        let split = split.min(input.len());
        let (prefix, suffix) = input.split_at(split);

        let mut parser1 = Parser::new();
        let _ = emit(&mut parser1, prefix);

        let mut parser2 = Parser::new();
        let dumped = parser1.dump();
        let dump_output = dumped
            .chars()
            .filter_map(|ch| parser2.feed(ch))
            .collect::<Vec<_>>();

        prop_assert!(dump_output.is_empty());
        parser1.assert_eq(&parser2);

        let suffix_output1 = emit(&mut parser1, suffix);
        let suffix_output2 = emit(&mut parser2, suffix);

        prop_assert_eq!(suffix_output1, suffix_output2);
        parser1.assert_eq(&parser2);
    }

    #[test]
    fn prop_cancel_then_continue(
        prefix in gen_non_ground_prefix(),
        cancel in prop::sample::select(vec!['\x18', '\x1a']),
        suffix in gen_printable_text(16),
    ) {
        let mut parser = Parser::new();

        let prefix_output = emit(&mut parser, &prefix);

        prop_assert!(prefix_output.is_empty());
        prop_assert_ne!(parser.state, State::Ground);

        let cancel_output = parser.feed(cancel);

        prop_assert_eq!(cancel_output, None);
        prop_assert_eq!(parser.state, State::Ground);

        let suffix_output = emit(&mut parser, &suffix);
        let expected = suffix.iter().copied().map(Function::Print).collect::<Vec<_>>();

        prop_assert_eq!(suffix_output, expected);
        prop_assert_eq!(parser.state, State::Ground);
    }
}
