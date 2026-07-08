use super::{Buffer, VisualPosition};
use crate::line::Line;
use crate::pen::Pen;
use pretty_assertions::assert_eq;
use proptest::prelude::*;

#[test]
fn text() {
    let mut buffer = Buffer::new(10, 5, None, None);

    assert_eq!(buffer.text(), vec!["", "", "", "", ""]);

    buffer.print((0, 0), 'x', Pen::default());
    buffer.print((1, 1), 'x', Pen::default());
    buffer.print((2, 2), 'x', Pen::default());
    buffer.print((3, 3), 'x', Pen::default());
    buffer.print((4, 4), 'x', Pen::default());
    assert_eq!(buffer.text(), vec!["x", " x", "  x", "   x", "    x"]);

    buffer.wrap(0);
    buffer.wrap(3);
    assert_eq!(
        buffer.text(),
        vec!["x          x", "  x", "   x          x"]
    );
}

#[test]
fn scroll_up() {
    let content = vec![
        ("aaaa", true),
        ("aaaa", true),
        ("aa  ", false),
        ("bb", false),
        ("cccc", true),
        ("cccc", true),
        ("cc", false),
    ];

    let pen = Pen::default();

    // whole view

    let mut buf = buffer(&content, None, 0);

    buf.scroll_up(0..content.len(), 1, &pen);

    assert_eq!(line(&buf[0]), "aaaa⏎");
    assert_eq!(line(&buf[1]), "aa  ");
    assert_eq!(line(&buf[2]), "bb  ");
    assert_eq!(line(&buf[3]), "cccc⏎");
    assert_eq!(line(&buf[4]), "cccc⏎");
    assert_eq!(line(&buf[5]), "cc  ");
    assert_eq!(line(&buf[6]), "    ");
    assert_eq!(buf.text().join("\n"), "aaaaaaaaaa\nbb\ncccccccccc\n");
    assert_eq!(buf.lines.len(), 8);
    assert!(buf.lines[0].wrapped);

    // top of the view

    let mut buf = buffer(&content, None, 0);

    buf.scroll_up(0..5, 1, &pen);

    assert_eq!(line(&buf[0]), "aaaa⏎");
    assert_eq!(line(&buf[1]), "aa  ");
    assert_eq!(line(&buf[2]), "bb  ");
    assert_eq!(line(&buf[3]), "cccc");
    assert_eq!(line(&buf[4]), "    ");
    assert_eq!(line(&buf[5]), "cccc⏎");
    assert_eq!(line(&buf[6]), "cc  ");
    assert_eq!(buf.text().join("\n"), "aaaaaaaaaa\nbb\ncccc\n\ncccccc");
    assert_eq!(buf.lines.len(), 8);
    assert!(buf.lines[0].wrapped);

    // bottom of the view

    let mut buf = buffer(&content, None, 0);

    buf.scroll_up(1..content.len(), 1, &pen);

    assert_eq!(line(&buf[0]), "aaaa");
    assert_eq!(line(&buf[1]), "aa  ");
    assert_eq!(line(&buf[2]), "bb  ");
    assert_eq!(line(&buf[3]), "cccc⏎");
    assert_eq!(line(&buf[4]), "cccc⏎");
    assert_eq!(line(&buf[5]), "cc  ");
    assert_eq!(line(&buf[6]), "    ");
    assert_eq!(buf.text().join("\n"), "aaaa\naa\nbb\ncccccccccc\n");
    assert_eq!(buf.lines.len(), 7);

    // no scrollback limit

    let mut buf = buffer(&content, None, 0);

    buf.scroll_up(0..content.len(), 5, &pen);

    assert_eq!(buf.lines.len(), 12);

    // scrollback limit of 0

    let mut buf = buffer(&content, Some(0), 0);

    buf.scroll_up(0..content.len(), 5, &pen);

    assert_eq!(buf.lines.len(), 12);

    buf.gc();

    assert_eq!(buf.lines.len(), 7);

    // scrollback limit of 3

    let mut buf = buffer(&content, Some(3), 0);

    buf.scroll_up(0..content.len(), 5, &pen);

    assert_eq!(buf.lines.len(), 12);

    buf.gc();

    assert_eq!(buf.lines.len(), 10);
}

fn line(line: &Line) -> String {
    let mut t = line.text();

    if line.wrapped {
        t.push('⏎');
    }

    t
}

#[test]
fn resize_shorter() {
    let content = vec![
        ("aa  ", false),
        ("bbbb", true),
        ("bbbb", true),
        ("bb", false),
        ("cc", false),
    ];

    // cursor at the top

    for scrollback in [0, 20] {
        let (view, cursor) = resize_buffer(scrollback, content.clone(), 4, 3, (0, 0));

        assert_eq!(cursor, (0, 0));
        assert_eq!(view, vec!["aa  ", "bbbb", "bbbb"]);
    }

    // cursor at the bottom

    for scrollback in [0, 20] {
        let (view, cursor) = resize_buffer(scrollback, content.clone(), 4, 3, (0, 4));

        assert_eq!(cursor, (0, 2));
        assert_eq!(view, vec!["bbbb", "bb  ", "cc  "]);
    }

    // cursor in the middle

    for scrollback in [0, 20] {
        let (view, cursor) = resize_buffer(scrollback, content.clone(), 4, 2, (0, 3));

        assert_eq!(cursor, (0, 1));
        assert_eq!(view, vec!["bbbb", "bb  "]);
    }
}

#[test]
fn resize_taller() {
    let content = vec![
        ("aa  ", false),
        ("bbbb", true),
        ("bbbb", true),
        ("bb", false),
        ("cc", false),
    ];

    // cursor at the top, no scrollback

    let (view, cursor) = resize_buffer(0, content.clone(), 4, 7, (0, 0));

    assert_eq!(cursor, (0, 0));
    assert_eq!(
        view,
        vec!["aa  ", "bbbb", "bbbb", "bb  ", "cc  ", "    ", "    "]
    );

    // cursor at the top, with scrollback

    let (view, cursor) = resize_buffer(20, content.clone(), 4, 7, (0, 0));

    assert_eq!(cursor, (0, 2));
    assert_eq!(
        view,
        vec!["ssss", "ssss", "aa  ", "bbbb", "bbbb", "bb  ", "cc  "]
    );

    // cursor at the bottom, no scrollback

    let (view, cursor) = resize_buffer(0, content.clone(), 4, 7, (0, 4));

    assert_eq!(cursor, (0, 4));
    assert_eq!(
        view,
        vec!["aa  ", "bbbb", "bbbb", "bb  ", "cc  ", "    ", "    "]
    );

    // cursor at the bottom, with scrollback

    let (view, cursor) = resize_buffer(20, content.clone(), 4, 7, (0, 4));

    assert_eq!(cursor, (0, 6));
    assert_eq!(
        view,
        vec!["ssss", "ssss", "aa  ", "bbbb", "bbbb", "bb  ", "cc  "]
    );

    // cursor in the middle, no scrollback

    let (view, cursor) = resize_buffer(0, content.clone(), 4, 7, (0, 3));

    assert_eq!(cursor, (0, 3));
    assert_eq!(
        view,
        vec!["aa  ", "bbbb", "bbbb", "bb  ", "cc  ", "    ", "    "]
    );

    // cursor in the middle, with scrollback

    let (view, cursor) = resize_buffer(20, content.clone(), 4, 7, (0, 3));

    assert_eq!(cursor, (0, 5));
    assert_eq!(
        view,
        vec!["ssss", "ssss", "aa  ", "bbbb", "bbbb", "bb  ", "cc  "]
    );

    // cursor below last row

    for scrollback in [0, 20] {
        let (_, cursor) = resize_buffer(scrollback, content.clone(), 4, 8, (2, 6));

        assert_eq!(cursor, (2, 6));
    }
}

#[test]
fn resize_wider() {
    let content = vec![
        ("aa  ", false),
        ("bbbb", true),
        ("bbbb", true),
        ("bb", false),
        ("cc", false),
    ];

    // cursor at the top, no scrollback

    let (view, cursor) = resize_buffer(0, content.clone(), 6, 5, (0, 0));

    assert_eq!(cursor, (0, 0));
    assert_eq!(view, vec!["aa    ", "bbbbbb", "bbbb  ", "cc    ", "      "]);

    // cursor at the top, with scrollback

    let (view, cursor) = resize_buffer(20, content.clone(), 6, 5, (0, 0));

    assert_eq!(cursor, (0, 1));
    assert_eq!(view, vec!["ssss  ", "aa    ", "bbbbbb", "bbbb  ", "cc    "]);

    // cursor at the bottom, no scrollback

    let (view, cursor) = resize_buffer(0, content.clone(), 6, 5, (0, 4));

    assert_eq!(cursor, (0, 3));
    assert_eq!(view, vec!["aa    ", "bbbbbb", "bbbb  ", "cc    ", "      "]);

    // cursor at the bottom, with scrollback

    let (view, cursor) = resize_buffer(20, content.clone(), 6, 5, (0, 4));

    assert_eq!(cursor, (0, 4));
    assert_eq!(view, vec!["ssss  ", "aa    ", "bbbbbb", "bbbb  ", "cc    "]);

    // cursor in the middle, no scrollback

    let (view, cursor) = resize_buffer(0, content.clone(), 6, 5, (1, 2));

    assert_eq!(cursor, (5, 1));
    assert_eq!(view, vec!["aa    ", "bbbbbb", "bbbb  ", "cc    ", "      "]);

    // cursor in the middle, with scrollback

    let (view, cursor) = resize_buffer(20, content.clone(), 6, 5, (1, 2));

    assert_eq!(cursor, (5, 2));
    assert_eq!(view, vec!["ssss  ", "aa    ", "bbbbbb", "bbbb  ", "cc    "]);
}

#[test]
fn resize_narrower() {
    let content = vec![
        ("aa  ", false),
        ("bbbb", true),
        ("bbbb", true),
        ("bb", false),
        ("cc", false),
    ];

    // cursor at the top, no scrollback

    let (view, cursor) = resize_buffer(0, content.clone(), 2, 5, (0, 0));

    assert_eq!(cursor, (0, 0));
    assert_eq!(view, vec!["aa", "bb", "bb", "bb", "bb"]);

    // cursor at the top, with scrollback

    let (view, cursor) = resize_buffer(20, content.clone(), 2, 5, (0, 0));

    assert_eq!(cursor, (0, 0));
    assert_eq!(view, vec!["aa", "bb", "bb", "bb", "bb"]);

    // cursor at the bottom, no scrollback

    let (view, cursor) = resize_buffer(0, content.clone(), 2, 5, (0, 4));

    assert_eq!(cursor, (0, 4));
    assert_eq!(view, vec!["bb", "bb", "bb", "bb", "cc"]);

    // cursor at the bottom, with scrollback

    let (view, cursor) = resize_buffer(20, content.clone(), 2, 5, (0, 4));

    assert_eq!(cursor, (0, 4));
    assert_eq!(view, vec!["bb", "bb", "bb", "bb", "cc"]);

    // cursor in the middle, no scrollback

    let (view, cursor) = resize_buffer(0, content.clone(), 2, 5, (1, 2));

    assert_eq!(cursor, (1, 1));
    assert_eq!(view, vec!["bb", "bb", "bb", "bb", "cc"]);

    // cursor in the middle, with scrollback

    let (view, cursor) = resize_buffer(20, content.clone(), 2, 5, (1, 2));

    assert_eq!(cursor, (1, 1));
    assert_eq!(view, vec!["bb", "bb", "bb", "bb", "cc"]);

    // cursor in the middle, no scrollback, last lines wrapped

    let (view, cursor) = resize_buffer(
        0,
        vec![
            ("aa  ", false),
            ("bbbb", true),
            ("bbb ", false),
            ("cccc", true),
            ("cc", false),
        ],
        2,
        5,
        (1, 2),
    );

    assert_eq!(cursor, (1, 0));
    assert_eq!(view, vec!["bb", "b ", "cc", "cc", "cc"]);
}

proptest! {
    #[test]
    fn prop_cursor_translation(scrollback_size in 0..20usize, wrapped in prop::collection::vec(prop::bool::ANY, 5), col in 0..10usize, row in 0..5usize) {
        let cols = 10;
        let rows = 5;
        let mut buffer = Buffer::new(cols, rows, None, None);
        buffer.add_scrollback(scrollback_size);

        for (i, w) in wrapped.iter().enumerate() {
            if *w {
                buffer.wrap(i);
            }
        }

        let rel_cur = buffer.logical_position((col, row), cols, rows);

        assert_eq!(buffer.relative_position(rel_cur, cols, rows), (col, row as isize));
    }
}

fn resize_buffer(
    scrollback_size: usize,
    content: Vec<(&str, bool)>,
    new_cols: usize,
    new_rows: usize,
    mut cursor: VisualPosition,
) -> (Vec<String>, VisualPosition) {
    let mut buffer = buffer(&content, None, scrollback_size);
    cursor = buffer.resize(new_cols, new_rows, cursor);

    let view = buffer.view().map(|line| line.text()).collect::<Vec<_>>();

    (view, cursor)
}

fn buffer(
    content: &[(&str, bool)],
    scrollback_limit: Option<usize>,
    scrollback_size: usize,
) -> Buffer {
    let cols = content[0].0.len();
    let rows = content.len();
    let mut buffer = Buffer::new(cols, rows, scrollback_limit, None);

    if !matches!(scrollback_limit, Some(0)) {
        buffer.add_scrollback(scrollback_size);
    }

    for (row, (line, wrapped)) in content.iter().enumerate() {
        for (col, ch) in line.chars().enumerate() {
            buffer.print((col, row), ch, Pen::default());
        }

        if *wrapped {
            buffer.wrap(row);
        }
    }

    buffer
}
