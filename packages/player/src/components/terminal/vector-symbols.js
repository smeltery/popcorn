const SYMBOL_STROKE = 0.05;
const CELL_RATIO = 9.0375 / 20;

export function getVectorSymbolDef(codepoint) {
  const stroke = `stroke="currentColor" stroke-width="${SYMBOL_STROKE}" stroke-linejoin="miter" stroke-linecap="square"`;
  const strokeButt = `stroke="currentColor" stroke-width="${SYMBOL_STROKE}" stroke-linejoin="miter" stroke-linecap="butt"`;
  const stroked = (d) => `<path d="${d}" fill="none" ${stroke}/>`;
  const third = 1 / 3;
  const twoThirds = 2 / 3;

  switch (codepoint) {
    // ◢ - black lower right triangle (https://symbl.cc/en/25E2/)
    case 0x25e2:
      return '<path d="M1,1 L1,0 L0,1 Z" fill="currentColor"/>' + stroked("M1,1 L1,0 L0,1 Z");

    // ◣ - black lower left triangle (https://symbl.cc/en/25E3/)
    case 0x25e3:
      return '<path d="M0,1 L0,0 L1,1 Z" fill="currentColor"/>' + stroked("M0,1 L0,0 L1,1 Z");

    // ◤ - black upper left triangle (https://symbl.cc/en/25E4/)
    case 0x25e4:
      return '<path d="M0,0 L1,0 L0,1 Z" fill="currentColor"/>' + stroked("M0,0 L1,0 L0,1 Z");

    // ◥ - black upper right triangle (https://symbl.cc/en/25E5/)
    case 0x25e5:
      return '<path d="M1,0 L1,1 L0,0 Z" fill="currentColor"/>' + stroked("M1,0 L1,1 L0,0 Z");

    case 0x268f: {
      // ⚏ - digram for greater yin (https://symbl.cc/en/268F/)
      const horizontalGap = 0.15;
      const verticalGap = 0.2;
      const lineHeight = 0.17;
      const halfHorizontalGap = horizontalGap / 2;
      const halfVerticalGap = verticalGap / 2;
      const toViewBoxY = (offset) => 0.5 + offset * CELL_RATIO;
      const leftX1 = 0.5 - halfHorizontalGap;
      const rightX0 = 0.5 + halfHorizontalGap;
      const rightX1 = 1 + 0.02; // slight overdraw
      const topY0 = toViewBoxY(-halfVerticalGap - lineHeight);
      const topY1 = toViewBoxY(-halfVerticalGap);
      const bottomY0 = toViewBoxY(halfVerticalGap);
      const bottomY1 = toViewBoxY(halfVerticalGap + lineHeight);
      const rect = (x0, x1, y0, y1) => `M${x0},${y0} L${x1},${y0} L${x1},${y1} L${x0},${y1} Z`;

      return `<path d="${rect(0, leftX1, topY0, topY1)} ${rect(rightX0, rightX1, topY0, topY1)} ${rect(0, leftX1, bottomY0, bottomY1)} ${rect(rightX0, rightX1, bottomY0, bottomY1)}" fill="currentColor"/>`;
    }

    // 🬼 - lower left block diagonal lower middle left to lower centre (https://symbl.cc/en/1FB3C/)
    case 0x1fb3c:
      return (
        `<path d="M0,${twoThirds} L0,1 L0.5,1 Z" fill="currentColor"/>` +
        stroked(`M0,${twoThirds} L0,1 L0.5,1 Z`)
      );

    // 🬽 - lower left block diagonal lower middle left to lower right (https://symbl.cc/en/1FB3D/)
    case 0x1fb3d:
      return (
        `<path d="M0,${twoThirds} L0,1 L1,1 Z" fill="currentColor"/>` +
        stroked(`M0,${twoThirds} L0,1 L1,1 Z`)
      );

    // 🬾 - lower left block diagonal upper middle left to lower centre (https://symbl.cc/en/1FB3E/)
    case 0x1fb3e:
      return (
        `<path d="M0,${third} L0.5,1 L0,1 Z" fill="currentColor"/>` +
        stroked(`M0,${third} L0.5,1 L0,1 Z`)
      );

    // 🬿 - lower left block diagonal upper middle left to lower right (https://symbl.cc/en/1FB3F/)
    case 0x1fb3f:
      return (
        `<path d="M0,${third} L1,1 L0,1 Z" fill="currentColor"/>` +
        stroked(`M0,${third} L1,1 L0,1 Z`)
      );

    // 🭀 - lower left block diagonal upper left to lower centre (https://symbl.cc/en/1FB40/)
    case 0x1fb40:
      return '<path d="M0,0 L0.5,1 L0,1 Z" fill="currentColor"/>' + stroked("M0,0 L0.5,1 L0,1 Z");

    // 🭁 - lower right block diagonal upper middle left to upper centre (https://symbl.cc/en/1FB41/)
    case 0x1fb41:
      return (
        `<path d="M0,${third} L0,1 L1,1 L1,0 L0.5,0 Z" fill="currentColor"/>` +
        stroked(`M0,${third} L0,1 L1,1 L1,0 L0.5,0 Z`)
      );

    // 🭂 - lower right block diagonal upper middle left to upper right (https://symbl.cc/en/1FB42/)
    case 0x1fb42:
      return (
        `<path d="M0,${third} L0,1 L1,1 L1,0 Z" fill="currentColor"/>` +
        stroked(`M0,${third} L0,1 L1,1 L1,0 Z`)
      );

    // 🭃 - lower right block diagonal lower middle left to upper centre (https://symbl.cc/en/1FB43/)
    case 0x1fb43:
      return (
        `<path d="M0,${twoThirds} L0,1 L1,1 L1,0 L0.5,0 Z" fill="currentColor"/>` +
        stroked(`M0,${twoThirds} L0,1 L1,1 L1,0 L0.5,0 Z`)
      );

    // 🭄 - lower right block diagonal lower middle left to upper right (https://symbl.cc/en/1FB44/)
    case 0x1fb44:
      return (
        `<path d="M0,${twoThirds} L0,1 L1,1 L1,0 Z" fill="currentColor"/>` +
        stroked(`M0,${twoThirds} L0,1 L1,1 L1,0 Z`)
      );

    // 🭅 - lower right block diagonal lower left to upper centre (https://symbl.cc/en/1FB45/)
    case 0x1fb45:
      return (
        '<path d="M0.5,0 L1,0 L1,1 L0,1 Z" fill="currentColor"/>' +
        stroked("M0.5,0 L1,0 L1,1 L0,1 Z")
      );

    // 🭆 - lower right block diagonal lower middle left to upper middle right (https://symbl.cc/en/1FB46/)
    case 0x1fb46:
      return (
        `<path d="M0,${twoThirds} L0,1 L1,1 L1,${third} Z" fill="currentColor"/>` +
        stroked(`M0,${twoThirds} L0,1 L1,1 L1,${third} Z`)
      );

    // 🭇 - lower right block diagonal lower centre to lower middle right (https://symbl.cc/en/1FB47/)
    case 0x1fb47:
      return (
        `<path d="M0.5,1 L1,1 L1,${twoThirds} Z" fill="currentColor"/>` +
        stroked(`M0.5,1 L1,1 L1,${twoThirds} Z`)
      );

    // 🭈 - lower right block diagonal lower left to lower middle right (https://symbl.cc/en/1FB48/)
    case 0x1fb48:
      return (
        `<path d="M0,1 L1,1 L1,${twoThirds} Z" fill="currentColor"/>` +
        stroked(`M0,1 L1,1 L1,${twoThirds} Z`)
      );

    // 🭉 - lower right block diagonal lower centre to upper middle right (https://symbl.cc/en/1FB49/)
    case 0x1fb49:
      return (
        `<path d="M0.5,1 L1,1 L1,${third} Z" fill="currentColor"/>` +
        stroked(`M0.5,1 L1,1 L1,${third} Z`)
      );

    // 🭊 - lower right block diagonal lower left to upper middle right (https://symbl.cc/en/1FB4A/)
    case 0x1fb4a:
      return (
        `<path d="M0,1 L1,1 L1,${third} Z" fill="currentColor"/>` +
        stroked(`M0,1 L1,1 L1,${third} Z`)
      );

    // 🭋 - lower right block diagonal lower centre to upper right (https://symbl.cc/en/1FB4B/)
    case 0x1fb4b:
      return '<path d="M0.5,1 L1,0 L1,1 Z" fill="currentColor"/>' + stroked("M0.5,1 L1,0 L1,1 Z");

    // 🭌 - lower left block diagonal upper centre to upper middle right (https://symbl.cc/en/1FB4C/)
    case 0x1fb4c:
      return (
        `<path d="M0,0 L0.5,0 L1,${third} L1,1 L0,1 Z" fill="currentColor"/>` +
        stroked(`M0,0 L0.5,0 L1,${third} L1,1 L0,1 Z`)
      );

    // 🭍 - lower left block diagonal upper left to upper middle right (https://symbl.cc/en/1FB4D/)
    case 0x1fb4d:
      return (
        `<path d="M0,0 L0,1 L1,1 L1,${third} Z" fill="currentColor"/>` +
        stroked(`M0,0 L0,1 L1,1 L1,${third} Z`)
      );

    // 🭎 - lower left block diagonal upper centre to lower middle right (https://symbl.cc/en/1FB4E/)
    case 0x1fb4e:
      return (
        `<path d="M0,0 L0.5,0 L1,${twoThirds} L1,1 L0,1 Z" fill="currentColor"/>` +
        stroked(`M0,0 L0.5,0 L1,${twoThirds} L1,1 L0,1 Z`)
      );

    // 🭏 - lower left block diagonal upper left to lower middle right (https://symbl.cc/en/1FB4F/)
    case 0x1fb4f:
      return (
        `<path d="M0,0 L1,${twoThirds} L1,1 L0,1 Z" fill="currentColor"/>` +
        stroked(`M0,0 L1,${twoThirds} L1,1 L0,1 Z`)
      );

    // 🭐 - lower left block diagonal upper centre to lower right (https://symbl.cc/en/1FB50/)
    case 0x1fb50:
      return (
        '<path d="M0,0 L0.5,0 L1,1 L0,1 Z" fill="currentColor"/>' +
        stroked("M0,0 L0.5,0 L1,1 L0,1 Z")
      );

    // 🭑 - lower left block diagonal upper middle left to lower middle right (https://symbl.cc/en/1FB51/)
    case 0x1fb51:
      return (
        `<path d="M0,${third} L1,${twoThirds} L1,1 L0,1 Z" fill="currentColor"/>` +
        stroked(`M0,${third} L1,${twoThirds} L1,1 L0,1 Z`)
      );

    // 🭒 - upper right block diagonal lower middle left to lower centre (https://symbl.cc/en/1FB52/)
    case 0x1fb52:
      return (
        `<path d="M0,${twoThirds} L0,0 L1,0 L1,1 L0.5,1 Z" fill="currentColor"/>` +
        stroked(`M0,${twoThirds} L0,0 L1,0 L1,1 L0.5,1 Z`)
      );

    // 🭓 - upper right block diagonal lower middle left to lower right (https://symbl.cc/en/1FB53/)
    case 0x1fb53:
      return (
        `<path d="M0,${twoThirds} L0,0 L1,0 L1,1 Z" fill="currentColor"/>` +
        stroked(`M0,${twoThirds} L0,0 L1,0 L1,1 Z`)
      );

    // 🭔 - upper right block diagonal upper middle left to lower centre (https://symbl.cc/en/1FB54/)
    case 0x1fb54:
      return (
        `<path d="M0,${third} L0,0 L1,0 L1,1 L0.5,1 Z" fill="currentColor"/>` +
        stroked(`M0,${third} L0,0 L1,0 L1,1 L0.5,1 Z`)
      );

    // 🭕 - upper right block diagonal upper middle left to lower right (https://symbl.cc/en/1FB55/)
    case 0x1fb55:
      return (
        `<path d="M0,${third} L0,0 L1,0 L1,1 Z" fill="currentColor"/>` +
        stroked(`M0,${third} L0,0 L1,0 L1,1 Z`)
      );

    // 🭖 - upper right block diagonal upper left to lower centre (https://symbl.cc/en/1FB56/)
    case 0x1fb56:
      return (
        '<path d="M0,0 L1,0 L1,1 L0.5,1 Z" fill="currentColor"/>' +
        stroked("M0,0 L1,0 L1,1 L0.5,1 Z")
      );

    // 🭗 - upper left block diagonal upper middle left to upper centre (https://symbl.cc/en/1FB57/)
    case 0x1fb57:
      return (
        `<path d="M0,${third} L0.5,0 L0,0 Z" fill="currentColor"/>` +
        stroked(`M0,${third} L0.5,0 L0,0 Z`)
      );

    // 🭘 - upper left block diagonal upper middle left to upper right (https://symbl.cc/en/1FB58/)
    case 0x1fb58:
      return (
        `<path d="M0,0 L1,0 L0,${third} Z" fill="currentColor"/>` +
        stroked(`M0,0 L1,0 L0,${third} Z`)
      );

    // 🭙 - upper left block diagonal lower middle left to upper centre (https://symbl.cc/en/1FB59/)
    case 0x1fb59:
      return (
        `<path d="M0,0 L0.5,0 L0,${twoThirds} Z" fill="currentColor"/>` +
        stroked(`M0,0 L0.5,0 L0,${twoThirds} Z`)
      );

    // 🭚 - upper left block diagonal lower middle left to upper right (https://symbl.cc/en/1FB5A/)
    case 0x1fb5a:
      return (
        `<path d="M0,0 L1,0 L0,${twoThirds} Z" fill="currentColor"/>` +
        stroked(`M0,0 L1,0 L0,${twoThirds} Z`)
      );

    // 🭛 - upper left block diagonal lower left to upper centre (https://symbl.cc/en/1FB5B/)
    case 0x1fb5b:
      return '<path d="M0,0 L0.5,0 L0,1 Z" fill="currentColor"/>' + stroked("M0,0 L0.5,0 L0,1 Z");

    // 🭜 - upper left block diagonal lower middle left to upper middle right (https://symbl.cc/en/1FB5C/)
    case 0x1fb5c:
      return (
        `<path d="M0,0 L1,0 L1,${third} L0,${twoThirds} Z" fill="currentColor"/>` +
        stroked(`M0,0 L1,0 L1,${third} L0,${twoThirds} Z`)
      );

    // 🭝 - upper left block diagonal lower centre to lower middle right (https://symbl.cc/en/1FB5D/)
    case 0x1fb5d:
      return (
        `<path d="M0,0 L1,0 L1,${twoThirds} L0.5,1 L0,1 Z" fill="currentColor"/>` +
        stroked(`M0,0 L1,0 L1,${twoThirds} L0.5,1 L0,1 Z`)
      );

    // 🭞 - upper left block diagonal lower left to lower middle right (https://symbl.cc/en/1FB5E/)
    case 0x1fb5e:
      return (
        `<path d="M0,0 L1,0 L1,${twoThirds} L0,1 Z" fill="currentColor"/>` +
        stroked(`M0,0 L1,0 L1,${twoThirds} L0,1 Z`)
      );

    // 🭟 - upper left block diagonal lower centre to upper middle right (https://symbl.cc/en/1FB5F/)
    case 0x1fb5f:
      return (
        `<path d="M0,0 L1,0 L1,${third} L0.5,1 L0,1 Z" fill="currentColor"/>` +
        stroked(`M0,0 L1,0 L1,${third} L0.5,1 L0,1 Z`)
      );

    // 🭠 - upper left block diagonal lower left to upper middle right (https://symbl.cc/en/1FB60/)
    case 0x1fb60:
      return (
        `<path d="M0,0 L1,0 L1,${third} L0,1 Z" fill="currentColor"/>` +
        stroked(`M0,0 L1,0 L1,${third} L0,1 Z`)
      );

    // 🭡 - upper left block diagonal lower centre to upper right (https://symbl.cc/en/1FB61/)
    case 0x1fb61:
      return (
        '<path d="M0,0 L1,0 L0.5,1 L0,1 Z" fill="currentColor"/>' +
        stroked("M0,0 L1,0 L0.5,1 L0,1 Z")
      );

    // 🭢 - upper right block diagonal upper centre to upper middle right (https://symbl.cc/en/1FB62/)
    case 0x1fb62:
      return (
        `<path d="M0.5,0 L1,0 L1,${third} Z" fill="currentColor"/>` +
        stroked(`M0.5,0 L1,0 L1,${third} Z`)
      );

    // 🭣 - upper right block diagonal upper left to upper middle right (https://symbl.cc/en/1FB63/)
    case 0x1fb63:
      return (
        `<path d="M0,0 L1,0 L1,${third} Z" fill="currentColor"/>` +
        stroked(`M0,0 L1,0 L1,${third} Z`)
      );

    // 🭤 - upper right block diagonal upper centre to lower middle right (https://symbl.cc/en/1FB64/)
    case 0x1fb64:
      return (
        `<path d="M0.5,0 L1,0 L1,${twoThirds} Z" fill="currentColor"/>` +
        stroked(`M0.5,0 L1,0 L1,${twoThirds} Z`)
      );

    // 🭥 - upper right block diagonal upper left to lower middle right (https://symbl.cc/en/1FB65/)
    case 0x1fb65:
      return (
        `<path d="M0,0 L1,0 L1,${twoThirds} Z" fill="currentColor"/>` +
        stroked(`M0,0 L1,0 L1,${twoThirds} Z`)
      );

    // 🭦 - upper right block diagonal upper centre to lower right (https://symbl.cc/en/1FB66/)
    case 0x1fb66:
      return '<path d="M0.5,0 L1,0 L1,1 Z" fill="currentColor"/>' + stroked("M0.5,0 L1,0 L1,1 Z");

    // 🭧 - upper right block diagonal upper middle left to lower middle right (https://symbl.cc/en/1FB67/)
    case 0x1fb67:
      return (
        `<path d="M0,${third} L0,0 L1,0 L1,${twoThirds} Z" fill="currentColor"/>` +
        stroked(`M0,${third} L0,0 L1,0 L1,${twoThirds} Z`)
      );

    // 🭨 - upper and right and lower triangular three quarters block (https://symbl.cc/en/1FB68/)
    case 0x1fb68:
      return (
        '<path fill-rule="evenodd" d="M0,0 L1,0 L1,1 L0,1 Z M0,0 L0,1 L0.5,0.5 Z" fill="currentColor"/>' +
        `<path d="M0,0 L1,0 M0,1 L1,1 M1,0 L1,1" fill="none" ${stroke}/>` +
        `<path d="M0,0 L0.5,0.5 M0,1 L0.5,0.5" fill="none" ${strokeButt}/>`
      );

    // 🭩 - left and lower and right triangular three quarters block (https://symbl.cc/en/1FB69/)
    case 0x1fb69:
      return (
        '<path fill-rule="evenodd" d="M0,0 L1,0 L1,1 L0,1 Z M0,0 L1,0 L0.5,0.5 Z" fill="currentColor"/>' +
        `<path d="M0,0 L0,1 M1,0 L1,1 M0,1 L1,1" fill="none" ${stroke}/>` +
        `<path d="M0,0 L0.5,0.5 M1,0 L0.5,0.5" fill="none" ${strokeButt}/>`
      );

    // 🭪 - upper and left and lower triangular three quarters block (https://symbl.cc/en/1FB6A/)
    case 0x1fb6a:
      return (
        '<path fill-rule="evenodd" d="M0,0 L1,0 L1,1 L0,1 Z M1,0 L1,1 L0.5,0.5 Z" fill="currentColor"/>' +
        `<path d="M0,0 L1,0 M0,1 L1,1 M0,0 L0,1" fill="none" ${stroke}/>` +
        `<path d="M1,0 L0.5,0.5 M1,1 L0.5,0.5" fill="none" ${strokeButt}/>`
      );

    // 🭫 - left and upper and right triangular three quarters block (https://symbl.cc/en/1FB6B/)
    case 0x1fb6b:
      return (
        '<path fill-rule="evenodd" d="M0,0 L1,0 L1,1 L0,1 Z M0,1 L1,1 L0.5,0.5 Z" fill="currentColor"/>' +
        `<path d="M0,0 L1,0 M0,0 L0,1 M1,0 L1,1" fill="none" ${stroke}/>` +
        `<path d="M0,1 L0.5,0.5 M1,1 L0.5,0.5" fill="none" ${strokeButt}/>`
      );

    // 🭬 - left triangular one quarter block (https://symbl.cc/en/1FB6C/)
    case 0x1fb6c:
      return (
        '<path d="M0,0 L0,1 L0.5,0.5 Z" fill="currentColor"/>' + stroked("M0,0 L0,1 L0.5,0.5 Z")
      );

    // powerline right full triangle (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0b0:
      return '<path d="M0,0 L1,0.5 L0,1 Z" fill="currentColor"/>';

    // powerline right bracket (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0b1:
      return '<path d="M0,0 L1,0.5 L0,1" fill="none" stroke="currentColor" stroke-width="0.07" stroke-linejoin="miter"/>';

    // powerline left full triangle (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0b2:
      return '<path d="M1,0 L0,0.5 L1,1 Z" fill="currentColor"/>';

    // powerline left bracket (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0b3:
      return '<path d="M1,0 L0,0.5 L1,1" fill="none" stroke="currentColor" stroke-width="0.07" stroke-linejoin="miter"/>';

    // nf-ple-right_half_circle_thick (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0b4:
      return '<path d="M0,0 A1,0.5 0 0 1 0,1 Z" fill="currentColor"/>';

    // nf-ple-right_half_circle_thin (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0b5:
      return '<path d="M0,0 A1,0.5 0 0 1 0,1" fill="none" stroke="currentColor" stroke-width="0.07"/>';

    // nf-ple-left_half_circle_thick (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0b6:
      return '<path d="M1,0 A1,0.5 0 0 0 1,1 Z" fill="currentColor"/>';

    // nf-ple-left_half_circle_thin (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0b7:
      return '<path d="M1,0 A1,0.5 0 0 0 1,1" fill="none" stroke="currentColor" stroke-width="0.07"/>';

    // nf-ple-lower_left_triangle (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0b8:
      return '<path d="M0,1 L0,0 L1,1 Z" fill="currentColor"/>';

    // nf-ple-backslash_separator (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0b9:
    // nf-ple-backslash_separator_redundant (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0bf:
      return '<path d="M0,0 L1,1" fill="none" stroke="currentColor" stroke-width="0.07"/>';

    // nf-ple-lower_right_triangle (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0ba:
      return '<path d="M1,1 L1,0 L0,1 Z" fill="currentColor"/>';

    // nf-ple-forwardslash_separator (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0bb:
    // nf-ple-forwardslash_separator_redundant (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0bd:
      return '<path d="M0,1 L1,0" fill="none" stroke="currentColor" stroke-width="0.07"/>';

    // nf-ple-upper_left_triangle (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0bc:
      return '<path d="M0,0 L1,0 L0,1 Z" fill="currentColor"/>';

    // nf-ple-upper_right_triangle (https://www.nerdfonts.com/cheat-sheet)
    case 0xe0be:
      return '<path d="M1,0 L1,1 L0,0 Z" fill="currentColor"/>';

    default:
      return null;
  }
}

export const POWERLINE_SYMBOLS = new Set([
  0xe0b0, 0xe0b1, 0xe0b2, 0xe0b3, 0xe0b4, 0xe0b5, 0xe0b6, 0xe0b7, 0xe0b8, 0xe0b9, 0xe0ba, 0xe0bb,
  0xe0bc, 0xe0bd, 0xe0be, 0xe0bf,
]);
export const POWERLINE_SYMBOL_NUDGE = 0.02;
