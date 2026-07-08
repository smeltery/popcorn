use super::common::*;

#[test]
fn auto_wrap_mode() {
    let mut term = Terminal::new((4, 4), None);

    term.execute(Decset(dec_modes([DecMode::AutoWrap])));
    feed(&mut term, "abcdef");

    assert_eq!(text(&term), "abcd\nef|\n\n");

    let mut term = Terminal::new((4, 4), None);

    term.execute(Decrst(dec_modes([DecMode::AutoWrap])));
    feed(&mut term, "abcdef");

    assert_eq!(text(&term), "abc|f\n\n\n");
}

#[test]
fn insert_mode() {
    let mut term = Terminal::new((4, 4), None);

    feed(&mut term, "abcd");
    term.execute(Cub(2));
    term.execute(Sm(ansi_modes([AnsiMode::Insert])));
    feed(&mut term, "ef");

    assert_eq!(text(&term), "aef|b\n\n\n");

    feed(&mut term, "ghij");

    assert_eq!(text(&term), "aefg\nhij|\n\n");
}

#[test]
fn print_at_the_end_of_the_screen() {
    let mut term = Terminal::new((4, 6), None);

    feed(&mut term, "xxxxxxxxxx");
    term.execute(Cup(50, 1));
    feed(&mut term, "yyy");
    term.execute(Cuf(50));
    feed(&mut term, "zzz");

    assert_eq!(text(&term), "xxxx\nxx\n\n\nyyyz\nzz|");

    let mut term = Terminal::new((4, 6), None);

    feed(&mut term, "\nxxxxxxxxxx");
    term.execute(Decstbm(2, 4));
    term.execute(Cup(1, 1));
    feed(&mut term, "yyy");
    term.execute(Cuf(50));
    feed(&mut term, "zzz");

    assert_eq!(text(&term), "yyyz\nzz|xx\nxxxx\nxx\n\n");

    let mut term = Terminal::new((4, 6), None);

    term.execute(Decstbm(0, 3));
    feed(&mut term, "xxxxxxxxxx");
    term.execute(Cup(50, 1));
    feed(&mut term, "yyy");
    term.execute(Cuf(50));
    feed(&mut term, "zzz");

    assert_eq!(text(&term), "xxxx\nxxxx\nxx\n\n\nzz|yz");
}

#[test]
fn wide_chars() {
    let mut term = Terminal::new((20, 2), None);

    feed(&mut term, "ハローワールド");
    assert_eq!(text(&term), "ハローワールド|\n");

    term.execute(Cub(5));
    assert_eq!(term.cursor().col, 9);
    assert_eq!(text(&term), "ハローワ|ールド\n");
}

#[test]
fn print_wide_char_on_wide_tail_with_one_col_right_and_autowrap() {
    let mut term = Terminal::new((4, 2), None);

    feed(&mut term, "Aハz");
    term.execute(Cub(1));
    term.execute(Print('界'));

    assert_eq!(term.cursor(), (4, 0));
    assert_eq!(text(&term), "A 界|\n");
    assert_eq!(wrapped(&term), vec![false, false]);

    let row0 = term.view().next().unwrap();
    assert_eq!(row0.text(), "A 界");

    assert_eq!(
        row0.cells()
            .iter()
            .map(|cell| (cell.char(), cell.occupancy()))
            .collect::<Vec<_>>(),
        vec![
            ('A', Occupancy::Single),
            (' ', Occupancy::Single),
            ('界', Occupancy::WideHead),
            (' ', Occupancy::WideTail),
        ]
    );
}

#[test]
fn print_wide_char_on_wide_tail_with_one_col_right_and_no_autowrap() {
    let mut term = Terminal::new((4, 2), None);

    term.execute(Decrst(dec_modes([DecMode::AutoWrap])));
    feed(&mut term, "Aハz");
    term.execute(Cub(1));
    term.execute(Print('界'));

    assert_eq!(term.cursor(), (3, 0));
    assert_eq!(text(&term), "A |界\n");
    assert_eq!(wrapped(&term), vec![false, false]);

    let row0 = term.view().next().unwrap();
    assert_eq!(row0.text(), "A 界");

    assert_eq!(
        row0.cells()
            .iter()
            .map(|cell| (cell.char(), cell.occupancy()))
            .collect::<Vec<_>>(),
        vec![
            ('A', Occupancy::Single),
            (' ', Occupancy::Single),
            ('界', Occupancy::WideHead),
            (' ', Occupancy::WideTail),
        ]
    );
}

#[test]
fn print_wide_char_in_occupied_last_column_preserves_cell_before_wrap() {
    let mut term = Terminal::new((4, 2), None);

    feed(&mut term, "abcz");
    term.execute(Cup(1, 4));
    term.execute(Print('界'));

    assert_eq!(term.cursor(), (2, 1));
    assert_eq!(text(&term), "abcz\n界|");
    assert_eq!(wrapped(&term), vec![true, false]);

    let mut view = term.view();
    let row0 = view.next().unwrap();
    let row1 = view.next().unwrap();

    assert_eq!(row0.text(), "abcz");

    assert_eq!(
        row0.cells()
            .iter()
            .map(|cell| (cell.char(), cell.occupancy()))
            .collect::<Vec<_>>(),
        vec![
            ('a', Occupancy::Single),
            ('b', Occupancy::Single),
            ('c', Occupancy::Single),
            ('z', Occupancy::Single),
        ]
    );

    assert_eq!(row1.text(), "界  ");

    assert_eq!(
        row1.cells()
            .iter()
            .map(|cell| (cell.char(), cell.occupancy()))
            .collect::<Vec<_>>(),
        vec![
            ('界', Occupancy::WideHead),
            (' ', Occupancy::WideTail),
            (' ', Occupancy::Single),
            (' ', Occupancy::Single),
        ]
    );
}

#[test]
fn execute_su() {
    let mut term = Terminal::new((4, 6), None);
    feed(&mut term, "aa\r\nbb\r\ncc\r\ndd\r\nee\r\nff");
    term.execute(Su(2));
    assert_eq!(text(&term), "cc\ndd\nee\nff\n\n  |");

    let mut term = Terminal::new((4, 6), None);
    feed(&mut term, "aa\r\nbb\r\ncc\r\ndd\r\nee\r\nff");
    term.execute(sgr(SetBoldIntensity));
    term.execute(Su(2));
    assert_eq!(text(&term), "cc\ndd\nee\nff\n\n  |");
    assert!(term.view().last().unwrap()[0].pen().is_bold());

    let mut term = Terminal::new((4, 6), None);

    feed(&mut term, "aa\r\nbb\r\ncc\r\ndd\r\nee\r\nff");
    term.execute(Decstbm(2, 5));
    term.execute(Cup(1, 1));
    term.execute(Su(2));

    assert_eq!(text(&term), "|aa\ndd\nee\n\n\nff");

    let mut term = Terminal::new((4, 6), None);

    feed(&mut term, "aaaaaa\r\nbbbbbb\r\ncccccc");
    term.execute(Su(2));

    assert_eq!(text(&term), "bbbb\nbb\ncccc\ncc\n\n  |");
    assert_eq!(wrapped(&term), vec![true, false, true, false, false, false]);

    let mut term = Terminal::new((4, 6), None);

    feed(&mut term, "aaaaaa\r\nbbbbbb\r\ncccccc");
    term.execute(Decstbm(2, 5));
    term.execute(Cup(1, 1));
    term.execute(Su(2));

    assert_eq!(text(&term), "|aaaa\nbb\ncccc\n\n\ncc");

    assert_eq!(
        wrapped(&term),
        vec![false, false, false, false, false, false]
    );
}

#[test]
fn execute_sd() {
    let mut term = Terminal::new((4, 6), None);

    feed(&mut term, "aa\r\nbb\r\ncc\r\ndd\r\nee\r\nff");
    term.execute(Sd(2));

    assert_eq!(text(&term), "\n\naa\nbb\ncc\ndd|");

    let mut term = Terminal::new((4, 6), None);

    feed(&mut term, "aa\r\nbb\r\ncc\r\ndd\r\nee\r\nff");
    term.execute(Decstbm(2, 5));
    term.execute(Cup(1, 1));
    term.execute(Sd(2));

    assert_eq!(text(&term), "|aa\n\n\nbb\ncc\nff");

    let mut term = Terminal::new((4, 6), None);

    feed(&mut term, "aaaaaa\r\nbbbbbb\r\ncccccc");
    term.execute(Sd(2));

    assert_eq!(text(&term), "\n\naaaa\naa\nbbbb\nbb|");
    assert_eq!(wrapped(&term), vec![false, false, true, false, true, false]);

    let mut term = Terminal::new((4, 6), None);

    feed(&mut term, "aaaaaa\r\nbbbbbb\r\ncccccc");
    term.execute(Decstbm(2, 5));
    term.execute(Cup(1, 1));
    term.execute(Sd(2));

    assert_eq!(text(&term), "|aaaa\n\n\naa\nbbbb\ncc");

    assert_eq!(
        wrapped(&term),
        vec![false, false, false, false, false, false]
    );
}
