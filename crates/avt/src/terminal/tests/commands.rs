use super::common::*;

#[test]
fn execute_sgr() {
    let mut term = Terminal::default();

    term.execute(sgr(SetBoldIntensity));

    assert!(term.pen.intensity == Intensity::Bold);

    term.execute(sgr(SetFaintIntensity));

    assert_eq!(term.pen.intensity, Intensity::Faint);

    term.execute(sgr(SetItalic));

    assert!(term.pen.is_italic());

    term.execute(sgr(SetUnderline));

    assert!(term.pen.is_underline());

    term.execute(sgr(SetBlink));

    assert!(term.pen.is_blink());

    term.execute(sgr(SetInverse));

    assert!(term.pen.is_inverse());

    term.execute(sgr(SetStrikethrough));

    assert!(term.pen.is_strikethrough());

    term.execute(sgr(SetForegroundColor(Color::Indexed(1))));

    assert_eq!(term.pen.foreground, Some(Color::Indexed(1)));

    term.execute(sgr(SetBackgroundColor(Color::Indexed(2))));

    assert_eq!(term.pen.background, Some(Color::Indexed(2)));

    term.execute(sgr(ResetForegroundColor));

    assert_eq!(term.pen.foreground, None);

    term.execute(sgr(ResetBackgroundColor));

    assert_eq!(term.pen.background, None);

    term.execute(Sgr(SgrOps::from(vec![
        SetBoldIntensity,
        SetForegroundColor(Color::Indexed(1)),
        SetBackgroundColor(Color::Indexed(2)),
        SetBlink,
        ResetIntensity,
    ])));

    assert_eq!(term.pen.intensity, Intensity::Normal);
    assert!(term.pen.is_blink());
    assert_eq!(term.pen.foreground, Some(Color::Indexed(1)));
    assert_eq!(term.pen.background, Some(Color::Indexed(2)));
}

#[test]
fn execute_lf() {
    let mut term = build_term(8, 2, 3, 0, "abc");

    term.execute(Lf);

    assert_eq!(term.cursor(), (3, 1));
    assert_eq!(text(&term), "abc\n   |");

    term.execute(Print('d'));
    term.execute(Lf);

    assert_eq!(term.cursor(), (4, 1));
    assert_eq!(text(&term), "   d\n    |");
}

#[test]
fn execute_cr() {
    let mut term = Terminal::new((4, 2), None);

    feed(&mut term, "abc");
    term.execute(Cr);
    term.execute(Print('d'));

    assert_eq!(term.cursor(), (1, 0));
    assert_eq!(text(&term), "d|bc\n");
}

#[test]
fn execute_nel() {
    let mut term = build_term(8, 2, 3, 0, "abc");

    term.execute(Nel);

    assert_eq!(term.cursor(), (0, 1));
    assert_eq!(text(&term), "abc\n|");

    term.execute(Print('d'));

    assert_eq!(text(&term), "abc\nd|");
}

#[test]
fn execute_bs() {
    let mut term = Terminal::new((4, 2), None);

    feed(&mut term, "a");
    term.execute(Bs);

    assert_eq!(text(&term), "|a\n");

    term.execute(Bs);

    assert_eq!(text(&term), "|a\n");

    feed(&mut term, "abcd");
    term.execute(Bs);

    assert_eq!(text(&term), "ab|cd\n");

    feed(&mut term, "cdef");
    term.execute(Bs);

    assert_eq!(text(&term), "abcd\ne|f");

    term.execute(Bs);

    assert_eq!(text(&term), "abcd\n|ef");

    term.execute(Bs);

    assert_eq!(text(&term), "abcd\n|ef");
}

#[test]
fn execute_cup() {
    let mut term = Terminal::new((4, 2), None);

    feed(&mut term, "abc\r\ndef");
    term.execute(Cup(1, 1));

    assert_eq!(term.cursor(), (0, 0));

    term.execute(Cup(10, 10));

    assert_eq!(term.cursor(), (3, 1));
}

#[test]
fn execute_cuu() {
    let mut term = Terminal::new((8, 4), None);

    feed(&mut term, "abcd\n\n\n");
    term.execute(Cuu(0));

    assert_eq!(term.cursor(), (4, 2));

    term.execute(Cuu(2));

    assert_eq!(term.cursor(), (4, 0));
}

#[test]
fn execute_cpl() {
    let mut term = Terminal::new((8, 4), None);

    feed(&mut term, "abcd\r\n\r\n\r\nef");

    assert_eq!(term.cursor(), (2, 3));

    term.execute(Cpl(0));

    assert_eq!(term.cursor(), (0, 2));

    term.execute(Cpl(2));

    assert_eq!(term.cursor(), (0, 0));
}

#[test]
fn execute_cnl() {
    let mut term = Terminal::new((4, 4), None);

    feed(&mut term, "ab");
    term.execute(Cnl(0));

    assert_eq!(term.cursor(), (0, 1));

    term.execute(Cnl(3));

    assert_eq!(term.cursor(), (0, 3));
}

#[test]
fn execute_vpa() {
    let mut term = Terminal::new((4, 4), None);

    feed(&mut term, "\r\n\r\naaa\r\nbbb");
    term.execute(Vpa(0));

    assert_eq!(term.cursor(), (3, 0));

    term.execute(Vpa(10));

    assert_eq!(term.cursor(), (3, 3));
}

#[test]
fn execute_cud() {
    let mut term = Terminal::new((8, 4), None);

    feed(&mut term, "abcd");
    term.execute(Cud(0));

    assert_eq!(text(&term), "abcd\n    |\n\n");

    term.execute(Cud(2));

    assert_eq!(text(&term), "abcd\n\n\n    |");
}

#[test]
fn execute_cuf() {
    let mut term = Terminal::new((4, 1), None);

    term.execute(Cuf(2));

    assert_eq!(text(&term), "  |");

    term.execute(Cuf(2));

    assert_eq!(text(&term), "   |");

    term.execute(Print('a'));

    assert_eq!(text(&term), "   a|");

    term.execute(Cuf(5));

    assert_eq!(text(&term), "   |a");

    feed(&mut term, "ab");
    term.execute(Cuf(10));

    assert_eq!(text(&term), "b  |");
}

#[test]
fn execute_cha() {
    let mut term = Terminal::new((8, 2), None);

    feed(&mut term, "abc");
    term.execute(Cha(0));

    assert_eq!(term.cursor(), (0, 0));

    term.execute(Cha(3));

    assert_eq!(term.cursor(), (2, 0));

    term.execute(Cha(20));

    assert_eq!(term.cursor(), (7, 0));
}

#[test]
fn execute_cub() {
    let mut term = Terminal::new((8, 2), None);

    feed(&mut term, "abcd");
    term.execute(Cub(2));

    assert_eq!(text(&term), "ab|cd\n");

    feed(&mut term, "cdef");
    term.execute(Cub(2));

    assert_eq!(text(&term), "abcd|ef\n");

    term.execute(Cub(10));

    assert_eq!(text(&term), "|abcdef\n");

    let mut term = Terminal::new((4, 2), None);

    feed(&mut term, "abcd");
    term.execute(Cub(0));

    assert_eq!(text(&term), "ab|cd\n");
}

#[test]
fn execute_ht() {
    let mut term = Terminal::new((20, 1), None);

    term.execute(Ht);
    assert_eq!(term.cursor(), (8, 0));

    term.execute(Ht);
    assert_eq!(term.cursor(), (16, 0));

    term.execute(Ht);
    assert_eq!(term.cursor(), (19, 0));
}

#[test]
fn execute_hts() {
    let mut term = Terminal::new((20, 1), None);

    term.execute(Cuf(5));
    term.execute(Hts);

    assert_eq!(term.tabs, vec![5, 8, 16]);

    term.execute(Cup(1, 1));
    term.execute(Ht);

    assert_eq!(term.cursor(), (5, 0));
}

#[test]
fn execute_cht() {
    let mut term = build_term(28, 1, 3, 0, "abcdefghijklmnopqrstuwxyzabc");

    term.execute(Cht(0));

    assert_eq!(term.cursor(), (8, 0));

    term.execute(Cht(2));

    assert_eq!(term.cursor(), (24, 0));

    term.execute(Cht(0));

    assert_eq!(term.cursor(), (27, 0));
}

#[test]
fn execute_cbt() {
    let mut term = build_term(28, 1, 26, 0, "abcdefghijklmnopqrstuwxyzabc");

    term.execute(Cbt(0));

    assert_eq!(term.cursor(), (24, 0));

    term.execute(Cbt(2));

    assert_eq!(term.cursor(), (8, 0));

    term.execute(Cbt(0));

    assert_eq!(term.cursor(), (0, 0));
}

#[test]
fn execute_rep() {
    let mut term = build_term(20, 2, 0, 0, "");

    term.execute(Rep(0));

    assert_eq!(text(&term), "|\n");

    term.execute(Print('A'));
    term.execute(Rep(0));

    assert_eq!(text(&term), "AA|\n");

    term.execute(Rep(3));

    assert_eq!(text(&term), "AAAAA|\n");

    term.execute(Cuf(5));
    term.execute(Rep(0));

    assert_eq!(text(&term), "AAAAA      |\n");
}

#[test]
fn execute_rep_after_wide_char() {
    let mut term = build_term(20, 2, 0, 0, "");

    term.execute(Print('ハ'));
    term.execute(Rep(3));

    assert_eq!(text(&term), "ハハハハ|\n");
}

#[test]
fn execute_rep_after_moving_into_wide_char_tail() {
    let mut term = build_term(20, 2, 0, 0, "");

    term.execute(Print('ハ'));
    term.execute(Cub(1));
    term.execute(Rep(3));

    assert_eq!(text(&term), " ハハハ|\n");
}

#[test]
fn dump_uses_rep_for_wide_char_runs() {
    let mut term = build_term(20, 2, 0, 0, "");

    feed(&mut term, "ハハハハハハ");

    let funs = term.dump();

    assert_eq!(funs[..2], [Print('ハ'), Rep(5)]);
}

#[test]
fn sgr_diff_prefers_targeted_ops_on_tie() {
    let from = pen(|pen| pen.intensity = Intensity::Bold);

    assert_eq!(
        dump::to_sgr_diff(&from, &Pen::default()),
        Some(sgr(ResetIntensity))
    );
}

#[test]
fn sgr_diff_uses_full_reset_when_shorter() {
    let from = pen(|pen| {
        pen.intensity = Intensity::Bold;
        pen.set_underline();
    });

    assert_eq!(dump::to_sgr_diff(&from, &Pen::default()), Some(sgr(Reset)));
}

#[test]
fn sgr_diff_uses_targeted_sets_for_first_styled_chunk() {
    let to = pen(|pen| {
        pen.intensity = Intensity::Bold;
        pen.foreground = Some(Color::Indexed(1));
    });

    assert_eq!(
        dump::to_sgr_diff(&Pen::default(), &to),
        Some(Sgr(SgrOps::from(vec![
            SetBoldIntensity,
            SetForegroundColor(Color::Indexed(1))
        ])))
    );
}

#[test]
fn execute_vpr() {
    let mut term = Terminal::new((4, 4), None);

    feed(&mut term, "ab");
    term.execute(Vpr(0));

    assert_eq!(term.cursor(), (2, 1));
    assert_eq!(text(&term), "ab\n  |\n\n");

    term.execute(Vpr(10));

    assert_eq!(term.cursor(), (2, 3));
    assert_eq!(text(&term), "ab\n\n\n  |");
}

#[test]
fn execute_ich() {
    let mut term = build_term(8, 2, 3, 0, "abcdefghijklmn");

    term.execute(Ich(0));

    assert_eq!(text(&term), "abc| defg\nijklmn");
    assert_eq!(wrapped(&term), vec![true, false]);

    term.execute(Ich(2));

    assert_eq!(text(&term), "abc|   de\nijklmn");

    term.execute(Ich(10));

    assert_eq!(text(&term), "abc|\nijklmn");

    let mut term = build_term(8, 2, 7, 0, "abcdefghijklmn");

    term.execute(Ich(10));
    assert_eq!(text(&term), "abcdefg|\nijklmn");
}

#[test]
fn execute_il() {
    let mut term = build_term(4, 4, 2, 1, "abcdefghij");

    term.execute(Il(0));

    assert_eq!(text(&term), "abcd\n  |\nefgh\nij");
    assert_eq!(wrapped(&term), vec![false, false, true, false]);

    term.execute(Cuu(1));
    term.execute(Il(0));

    assert_eq!(text(&term), "  |\nabcd\n\nefgh");
    assert_eq!(wrapped(&term), vec![false, false, false, false]);

    term.execute(Cud(3));
    term.execute(Il(100));

    assert_eq!(text(&term), "\nabcd\n\n  |");
}

#[test]
fn execute_dl() {
    let mut term = Terminal::new((4, 4), None);

    feed(&mut term, "abcdefghijklmn");
    term.execute(Cuu(2));
    term.execute(Dl(0));

    assert_eq!(text(&term), "abcd\nij|kl\nmn\n");
    assert_eq!(wrapped(&term), vec![false, true, false, false]);

    let mut term = Terminal::new((4, 4), None);

    feed(&mut term, "abcdefghijklmn");
    term.execute(Decstbm(1, 3));
    term.execute(Cup(2, 1));
    term.execute(Dl(0));

    assert_eq!(text(&term), "abcd\n|ijkl\n\nmn");
    assert_eq!(wrapped(&term), vec![false, false, false, false]);

    let mut term = Terminal::new((4, 4), None);

    feed(&mut term, "abcdefghijklmn");
    term.execute(Decstbm(1, 2));
    term.execute(Cup(4, 1));
    term.execute(Dl(0));

    assert_eq!(text(&term), "abcd\nefgh\nijkl\n|");
    assert_eq!(wrapped(&term), vec![true, true, false, false]);
}

#[test]
fn execute_el() {
    let mut term = build_term(4, 2, 2, 0, "abcd");

    term.execute(El(ElScope::ToRight));

    assert_eq!(text(&term), "ab|\n");

    let mut term = build_term(4, 2, 2, 0, "a");

    term.execute(El(ElScope::ToRight));

    assert_eq!(text(&term), "a |\n");

    let mut term = build_term(4, 2, 2, 0, "abcd");

    term.execute(El(ElScope::ToLeft));

    assert_eq!(text(&term), "  | d\n");

    let mut term = build_term(4, 2, 2, 0, "abcd");

    term.execute(El(ElScope::All));

    assert_eq!(text(&term), "  |\n");

    let mut term = Terminal::new((4, 3), None);

    feed(&mut term, "abcdefghij");
    term.execute(Cuu(1));
    term.execute(El(ElScope::ToRight));

    assert_eq!(text(&term), "abcd\nef|\nij");
    assert_eq!(wrapped(&term), vec![true, false, false]);

    let mut term = Terminal::new((4, 3), None);

    feed(&mut term, "abcdefghij");
    term.execute(Cuu(1));
    term.execute(El(ElScope::ToLeft));

    assert_eq!(text(&term), "abcd\n  | h\nij");
    assert_eq!(wrapped(&term), vec![true, true, false]);

    let mut term = Terminal::new((4, 3), None);

    feed(&mut term, "abcdefghij");
    term.execute(Cuu(1));
    term.execute(El(ElScope::All));

    assert_eq!(text(&term), "abcd\n  |\nij");
    assert_eq!(wrapped(&term), vec![true, false, false]);
}

#[test]
fn execute_ed() {
    let mut term = build_term(4, 3, 1, 1, "abc\r\ndef\r\nghi");

    term.execute(Ed(EdScope::Below));

    assert_eq!(text(&term), "abc\nd|\n");

    let mut term = build_term(4, 3, 1, 1, "abc\r\n\r\nghi");

    term.execute(Ed(EdScope::Below));

    assert_eq!(text(&term), "abc\n |\n");

    let mut term = build_term(4, 3, 1, 1, "abc\r\ndef\r\nghi");

    term.execute(Ed(EdScope::Above));

    assert_eq!(text(&term), "\n | f\nghi");

    let mut term = build_term(4, 3, 1, 1, "abc\r\ndef\r\nghi");

    term.execute(Ed(EdScope::All));

    assert_eq!(text(&term), "\n |\n");

    let mut term = build_term(4, 3, 1, 1, "abcdefghij");

    term.execute(Ed(EdScope::Below));

    assert_eq!(text(&term), "abcd\ne|\n");
    assert_eq!(wrapped(&term), vec![true, false, false]);

    let mut term = build_term(4, 3, 1, 1, "abcdefghij");

    term.execute(Ed(EdScope::Above));

    assert_eq!(text(&term), "\n | gh\nij");
    assert_eq!(wrapped(&term), vec![false, true, false]);

    let mut term = build_term(4, 3, 1, 1, "abcdefghij");

    term.execute(Ed(EdScope::All));

    assert_eq!(text(&term), "\n |\n");
    assert_eq!(wrapped(&term), vec![false, false, false]);
}

#[test]
fn execute_dch() {
    let mut term = build_term(8, 2, 3, 0, "abcdefghijkl");

    term.execute(Dch(0));

    assert_eq!(text(&term), "abc|efgh\nijkl");
    assert_eq!(wrapped(&term), vec![false, false]);

    term.execute(Dch(2));

    assert_eq!(text(&term), "abc|gh\nijkl");

    term.execute(Dch(10));

    assert_eq!(text(&term), "abc|\nijkl");

    term.execute(Cuf(10));
    term.execute(Dch(10));

    assert_eq!(text(&term), "abc    |\nijkl");
}

#[test]
fn execute_ech() {
    let mut term = build_term(8, 2, 3, 0, "abcdefghijkl");

    term.execute(Ech(0));

    assert_eq!(text(&term), "abc| efgh\nijkl");
    assert_eq!(wrapped(&term), vec![true, false]);

    term.execute(Ech(2));

    assert_eq!(text(&term), "abc|  fgh\nijkl");
    assert_eq!(wrapped(&term), vec![true, false]);

    term.execute(Ech(10));

    assert_eq!(text(&term), "abc|\nijkl");
    assert_eq!(wrapped(&term), vec![false, false]);

    term.execute(Cuf(3));
    term.execute(Ech(0));

    assert_eq!(text(&term), "abc   |\nijkl");
}

#[test]
fn execute_ri() {
    let mut term = build_term(8, 5, 0, 0, "abcd\r\nefgh\r\nijkl\r\nmnop\r\nqrst");

    term.execute(Ri);

    assert_eq!(text(&term), "|\nabcd\nefgh\nijkl\nmnop");

    term.execute(Decstbm(3, 4));
    term.execute(Cup(3, 1));
    term.execute(Ri);

    assert_eq!(text(&term), "\nabcd\n|\nefgh\nmnop");
}

#[test]
fn execute_sc_rc() {
    let mut term = build_term(4, 3, 0, 0, "");

    feed(&mut term, "  \n");
    term.execute(Decsc);
    feed(&mut term, " \n");
    term.execute(Decrc);

    assert_eq!(term.cursor(), (2, 1));

    let mut term = build_term(4, 3, 0, 0, "");

    feed(&mut term, "  \n");
    term.execute(Scosc);
    feed(&mut term, " \n");
    term.execute(Scorc);

    assert_eq!(term.cursor(), (2, 1));
}

#[test]
fn execute_sc_rc_restores_pen_and_modes() {
    fn assert_save_restore(save: Function, restore: Function) {
        let mut term = Terminal::new((4, 4), None);

        term.execute(Decrst(dec_modes([DecMode::AutoWrap])));
        term.execute(Decstbm(2, 4));
        term.execute(Decset(dec_modes([DecMode::Origin])));
        term.execute(Cup(2, 3));
        term.execute(sgr(SetBoldIntensity));
        term.execute(save);

        term.execute(Decset(dec_modes([DecMode::AutoWrap])));
        term.execute(Decrst(dec_modes([DecMode::Origin])));
        term.execute(Cup(4, 4));
        term.execute(sgr(Reset));
        term.execute(restore);

        assert_eq!(term.cursor(), (2, 2));
        assert_eq!(term.pen.intensity, Intensity::Bold);
        assert!(term.origin_mode);
        assert!(!term.auto_wrap_mode);
    }

    assert_save_restore(Decsc, Decrc);
    assert_save_restore(Scosc, Scorc);
}
