use super::common::*;

#[test]
fn charsets() {
    let mut term = build_term(6, 7, 0, 0, "");

    feed(&mut term, "alpty\r\n");
    term.execute(Gzd4(Charset::Drawing));
    feed(&mut term, "alpty\r\n");
    term.execute(So);
    feed(&mut term, "alpty\r\n");
    term.execute(G1d4(Charset::Drawing));
    feed(&mut term, "alpty\r\n");
    term.execute(G1d4(Charset::Ascii));
    feed(&mut term, "alpty\r\n");
    term.execute(Gzd4(Charset::Ascii));
    term.execute(Si);
    feed(&mut term, "alpty");

    assert_eq!(text(&term), "alpty\n▒┌⎻├≤\nalpty\n▒┌⎻├≤\nalpty\nalpty|\n");
}

#[test]
fn execute_decaln() {
    let mut term = Terminal::new((4, 2), None);

    feed(&mut term, "ab\r\nc");
    term.execute(Cup(2, 3));
    term.execute(Decaln);

    assert_eq!(term.cursor(), (2, 1));
    assert_eq!(text(&term), "EEEE\nEE|EE");
}

#[test]
fn resize_wider() {
    let mut term = Terminal::new((6, 6), None);

    term.resize(7, 6);

    assert_eq!(text(&term), "|\n\n\n\n\n");
    assert!(!term.view().any(|l| l.wrapped));

    term.resize(15, 6);

    assert_eq!(text(&term), "|\n\n\n\n\n");
    assert!(!term.view().any(|l| l.wrapped));

    let mut term = Terminal::new((6, 6), None);

    feed(&mut term, "000000111111222222333333444444555");

    assert_eq!(text(&term), "000000\n111111\n222222\n333333\n444444\n555|");
    assert_eq!(wrapped(&term), vec![true, true, true, true, true, false]);

    term.resize(7, 6);

    assert_eq!(text(&term), "0000001\n1111122\n2222333\n3334444\n44555|\n");
    assert_eq!(wrapped(&term), vec![true, true, true, true, false, false]);

    term.resize(15, 6);

    assert_eq!(text(&term), "000000111111222\n222333333444444\n555|\n\n\n");
    assert_eq!(wrapped(&term), vec![true, true, false, false, false, false]);

    let mut term = Terminal::new((4, 3), None);

    feed(&mut term, "000011\r\n22");

    assert_eq!(text(&term), "0000\n11\n22|");
    assert_eq!(wrapped(&term), vec![true, false, false]);

    term.resize(8, 3);

    assert_eq!(text(&term), "000011\n22|\n");
    assert_eq!(wrapped(&term), vec![false, false, false]);
}

#[test]
fn resize_narrower() {
    let mut term = Terminal::new((15, 6), None);

    term.resize(7, 6);

    assert_eq!(text(&term), "|\n\n\n\n\n");
    assert!(!term.view().any(|l| l.wrapped));

    term.resize(6, 6);

    assert_eq!(text(&term), "|\n\n\n\n\n");
    assert!(!term.view().any(|l| l.wrapped));

    let mut term = Terminal::new((8, 2), None);

    feed(&mut term, "\nabcdef");

    assert_eq!(wrapped(&term), vec![false, false]);

    term.resize(4, 2);

    assert_eq!(text(&term), "abcd\nef|");
    assert_eq!(wrapped(&term), vec![true, false]);

    let mut term = Terminal::new((15, 6), None);

    feed(&mut term, "000000111111222222333333444444555");

    assert_eq!(text(&term), "000000111111222\n222333333444444\n555|\n\n\n");
    assert_eq!(wrapped(&term), vec![true, true, false, false, false, false]);

    term.resize(7, 6);

    assert_eq!(text(&term), "2222333\n3334444\n44555|\n\n\n");
    assert_eq!(wrapped(&term), vec![true, true, false, false, false, false]);

    term.resize(6, 6);

    assert_eq!(text(&term), "333333\n444444\n555|\n\n\n");
    assert_eq!(wrapped(&term), vec![true, true, false, false, false, false]);
}

#[test]
fn resize() {
    let mut term = Terminal::new((8, 4), None);
    feed(&mut term, "abcdefgh\r\nijklmnop\r\nqrstuw");
    term.execute(Cup(4, 1));
    feed(&mut term, "AAA");

    term.resize(8, 5);

    assert_eq!(text(&term), "abcdefgh\nijklmnop\nqrstuw\nAAA|\n");

    feed(&mut term, "BBBBB");

    assert_eq!(term.cursor(), (8, 3));

    term.resize(4, 5);

    assert_eq!(text(&term), "qrst\nuw\nAAAB\nBBB|B\n");

    feed(&mut term, "\rCCC");

    assert_eq!(text(&term), "qrst\nuw\nAAAB\nCCC|B\n");
    assert_eq!(wrapped(&term), vec![true, false, true, false, false]);

    term.resize(3, 5);

    assert_eq!(text(&term), "tuw\nAAA\nBCC\nC|B\n");

    term.resize(5, 5);

    assert_eq!(text(&term), "qrstu\nw\nAAABC\nCC|B\n");

    feed(&mut term, "DDD");
    term.resize(6, 5);

    assert_eq!(text(&term), "op\nqrstuw\nAAABCC\nCDDD|\n");
}

#[test]
fn resize_taller() {
    let mut term = Terminal::new((6, 4), None);
    feed(&mut term, "AAA\n\rBBB\n\r");

    term.resize(6, 5);

    assert_eq!(text(&term), "AAA\nBBB\n|\n\n");
}

#[test]
fn resize_shorter() {
    let mut term = Terminal::new((6, 6), None);

    feed(&mut term, "AAA\n\rBBB\n\rCCC\n\r");

    term.resize(6, 5);

    assert_eq!(text(&term), "AAA\nBBB\nCCC\n|\n");

    term.resize(6, 3);

    assert_eq!(text(&term), "BBB\nCCC\n|");

    term.resize(6, 2);

    assert_eq!(text(&term), "CCC\n|");
}

#[test]
fn resize_vs_buffer_switching() {
    let mut term = Terminal::new((4, 4), None);

    feed(&mut term, "aaa\n\rbbb\n\rc\n\rddd");

    assert_eq!(term.cursor(), (3, 3));

    term.resize(4, 5);

    assert_eq!(text(&term), "aaa\nbbb\nc\nddd|\n");

    term.execute(Decset(dec_modes([DecMode::SaveCursorAltScreenBuffer])));

    assert_eq!(term.cursor(), (3, 3));

    term.resize(4, 2);

    assert_eq!(term.cursor(), (3, 1));

    term.resize(2, 3);
    term.resize(3, 3);

    term.execute(Decrst(dec_modes([DecMode::SaveCursorAltScreenBuffer])));

    assert_eq!(text(&term), "bbb\nc\ndd|d");
}

#[test]
fn execute_new_line_mode() {
    let mut term = build_term(8, 2, 3, 0, "abc");

    term.execute(Sm(ansi_modes([AnsiMode::NewLine])));
    term.execute(Lf);

    assert_eq!(term.cursor(), (0, 1));

    term.execute(Rm(ansi_modes([AnsiMode::NewLine])));
    term.execute(Cup(1, 4));
    term.execute(Lf);

    assert_eq!(term.cursor(), (3, 1));
}

#[test]
fn execute_cursor_keys_mode() {
    let mut term = Terminal::new((4, 2), None);

    assert!(!term.cursor_keys_app_mode());

    term.execute(Decset(dec_modes([DecMode::CursorKeys])));
    assert!(term.cursor_keys_app_mode());

    term.execute(Decrst(dec_modes([DecMode::CursorKeys])));
    assert!(!term.cursor_keys_app_mode());
}

#[test]
fn execute_text_cursor_visibility_mode() {
    let mut term = Terminal::new((4, 2), None);

    assert!(term.cursor.visible);

    term.execute(Decrst(dec_modes([DecMode::TextCursorEnable])));
    assert!(!term.cursor.visible);

    term.execute(Decset(dec_modes([DecMode::TextCursorEnable])));
    assert!(term.cursor.visible);
}

#[test]
fn execute_origin_mode() {
    let mut term = Terminal::new((4, 4), None);

    term.execute(Decstbm(2, 4));
    term.execute(Decset(dec_modes([DecMode::Origin])));

    assert_eq!(term.cursor(), (0, 1));

    term.execute(Cup(2, 1));
    assert_eq!(term.cursor(), (0, 2));

    term.execute(Decrst(dec_modes([DecMode::Origin])));
    assert_eq!(term.cursor(), (0, 0));
}

#[test]
fn execute_alt_screen_buffer_mode() {
    let mut term = Terminal::new((4, 3), None);

    feed(&mut term, "ab\r\ncd");

    assert_eq!(term.active_buffer_type(), BufferType::Primary);
    assert_eq!(text(&term), "ab\ncd|\n");

    term.execute(Decset(dec_modes([DecMode::AltScreenBuffer])));

    assert_eq!(term.active_buffer_type(), BufferType::Alternate);
    assert_eq!(text(&term), "\n  |\n");

    feed(&mut term, "xy");
    assert_eq!(text(&term), "\n  xy|\n");

    term.execute(Decrst(dec_modes([DecMode::AltScreenBuffer])));

    assert_eq!(term.active_buffer_type(), BufferType::Primary);
    assert_eq!(text(&term), "ab\ncd  |\n");
}

#[test]
fn execute_save_cursor_mode() {
    let mut term = Terminal::new((4, 4), None);

    term.execute(Decrst(dec_modes([DecMode::AutoWrap])));
    term.execute(Decstbm(2, 4));
    term.execute(Decset(dec_modes([DecMode::Origin])));
    term.execute(Cup(2, 3));
    term.execute(sgr(SetBoldIntensity));

    term.execute(Decset(dec_modes([DecMode::SaveCursor])));

    term.execute(Decset(dec_modes([DecMode::AutoWrap])));
    term.execute(Decrst(dec_modes([DecMode::Origin])));
    term.execute(Cup(4, 4));
    term.execute(sgr(Reset));

    term.execute(Decrst(dec_modes([DecMode::SaveCursor])));

    assert_eq!(term.cursor(), (2, 2));
    assert_eq!(term.pen.intensity, Intensity::Bold);
    assert!(term.origin_mode);
    assert!(!term.auto_wrap_mode);
}

#[test]
fn execute_decstr() {
    let mut term = Terminal::new((4, 3), None);

    feed(&mut term, "ab");
    term.execute(Decset(dec_modes([DecMode::AltScreenBuffer])));
    feed(&mut term, "xy");
    term.execute(Decrst(dec_modes([DecMode::TextCursorEnable])));
    term.execute(Sm(ansi_modes([AnsiMode::Insert, AnsiMode::NewLine])));
    term.execute(Decrst(dec_modes([DecMode::AutoWrap])));
    term.execute(Decset(dec_modes([DecMode::CursorKeys])));
    term.execute(Decstbm(2, 3));
    term.execute(Decset(dec_modes([DecMode::Origin])));
    term.execute(Cup(2, 3));
    term.execute(sgr(SetBoldIntensity));
    term.execute(G1d4(Charset::Drawing));
    term.execute(So);
    term.execute(Decsc);

    assert_eq!(term.active_buffer_type(), BufferType::Alternate);
    assert_eq!(term.cursor(), (2, 2));
    assert_eq!(text(&term), "  xy\n\n  |");
    assert!(!term.cursor.visible);
    assert!(term.insert_mode);
    assert!(term.origin_mode);
    assert!(!term.auto_wrap_mode);
    assert!(term.new_line_mode);
    assert!(term.cursor_keys_app_mode());
    assert_eq!(term.top_margin, 1);
    assert_eq!(term.bottom_margin, 2);
    assert_eq!(term.charsets, [Charset::Ascii, Charset::Drawing]);
    assert_eq!(term.active_charset, 1);
    assert_eq!(term.saved_ctx.cursor_col, 2);
    assert_eq!(term.saved_ctx.cursor_row, 2);
    assert_eq!(term.pen.intensity, Intensity::Bold);

    term.execute(Decstr);

    assert_eq!(term.active_buffer_type(), BufferType::Alternate);
    assert_eq!(term.cursor(), (2, 2));
    assert_eq!(text(&term), "  xy\n\n  |");
    assert!(term.cursor.visible);
    assert!(!term.insert_mode);
    assert!(!term.origin_mode);
    assert!(!term.auto_wrap_mode);
    assert!(term.new_line_mode);
    assert!(term.cursor_keys_app_mode());
    assert_eq!(term.top_margin, 0);
    assert_eq!(term.bottom_margin, 2);
    assert_eq!(term.charsets, [Charset::Ascii, Charset::Ascii]);
    assert_eq!(term.active_charset, 0);
    assert_eq!(term.saved_ctx, SavedCtx::default());
    assert_eq!(term.pen, crate::pen::Pen::default());
}

#[test]
fn execute_ris() {
    let mut term = Terminal::new((4, 3), None);

    feed(&mut term, "ab\r\ncd");
    term.execute(sgr(SetBoldIntensity));

    term.execute(Decset(dec_modes([
        DecMode::CursorKeys,
        DecMode::SaveCursorAltScreenBuffer,
    ])));

    feed(&mut term, "zz");

    term.execute(Ris);

    assert_eq!(term.active_buffer_type(), BufferType::Primary);
    assert_eq!(term.cursor(), (0, 0));
    assert_eq!(text(&term), "|\n\n");
    assert_eq!(term.pen, crate::pen::Pen::default());
    assert!(!term.cursor_keys_app_mode());
}

#[test]
fn resize_vs_tabs() {
    let mut term = Terminal::new((6, 2), None);

    assert_eq!(term.tabs, vec![]);

    term.resize(10, 2);

    assert_eq!(term.tabs, vec![8]);

    term.resize(30, 2);

    assert_eq!(term.tabs, vec![8, 16, 24]);

    term.resize(20, 2);

    assert_eq!(term.tabs, vec![8, 16]);
}

#[test]
fn resize_vs_saved_ctx() {
    use DecMode::*;

    let mut term = Terminal::new((20, 5), None);

    // move cursor forward by 15 cols
    term.execute(Cuf(15));

    assert_eq!(term.cursor.col, 15);

    // save cursor
    term.execute(Decsc);

    assert_eq!(term.saved_ctx.cursor_col, 15);

    // switch to alternate buffer
    term.execute(Decset(dec_modes([AltScreenBuffer])));

    // save cursor
    term.execute(Decsc);

    assert_eq!(term.saved_ctx.cursor_col, 15);

    // resize to 10x5
    term.resize(10, 5);

    assert_eq!(term.saved_ctx.cursor_col, 9);
}
