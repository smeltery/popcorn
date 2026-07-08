export const BLOCK_H_RES = 8;
export const BLOCK_V_RES = 24;

export function drawBlockGlyph(ctx, codepoint, x, y) {
  const unitX = BLOCK_H_RES / 8;
  const unitY = BLOCK_V_RES / 8;
  const halfX = BLOCK_H_RES / 2;
  const halfY = BLOCK_V_RES / 2;
  const sextantX = BLOCK_H_RES / 2;
  const sextantY = BLOCK_V_RES / 3;

  switch (codepoint) {
    case 0x2503:
      // box drawings heavy vertical (https://symbl.cc/en/2503/)
      ctx.fillRect(x + 3, y, 2, BLOCK_V_RES);
      break;

    case 0x2579:
      // box drawings heavy up (https://symbl.cc/en/2579/)
      ctx.fillRect(x + 3, y, 2, halfY);
      break;

    case 0x257b:
      // box drawings heavy down (https://symbl.cc/en/257B/)
      ctx.fillRect(x + 3, y + halfY, 2, halfY);
      break;

    case 0x2580:
      // upper half block (https://symbl.cc/en/2580/)
      ctx.fillRect(x, y, BLOCK_H_RES, halfY);
      break;

    case 0x2581:
      // lower one eighth block (https://symbl.cc/en/2581/)
      ctx.fillRect(x, y + unitY * 7, BLOCK_H_RES, unitY);
      break;

    case 0x2582:
      // lower one quarter block (https://symbl.cc/en/2582/)
      ctx.fillRect(x, y + unitY * 6, BLOCK_H_RES, unitY * 2);
      break;
    case 0x2583:
      // lower three eighths block (https://symbl.cc/en/2583/)
      ctx.fillRect(x, y + unitY * 5, BLOCK_H_RES, unitY * 3);
      break;

    case 0x2584:
      // lower half block (https://symbl.cc/en/2584/)
      ctx.fillRect(x, y + halfY, BLOCK_H_RES, halfY);
      break;

    case 0x2585:
      // lower five eighths block (https://symbl.cc/en/2585/)
      ctx.fillRect(x, y + unitY * 3, BLOCK_H_RES, unitY * 5);
      break;

    case 0x2586:
      // lower three quarters block (https://symbl.cc/en/2586/)
      ctx.fillRect(x, y + unitY * 2, BLOCK_H_RES, unitY * 6);
      break;

    case 0x2587:
      // lower seven eighths block (https://symbl.cc/en/2587/)
      ctx.fillRect(x, y + unitY, BLOCK_H_RES, unitY * 7);
      break;

    case 0x2588:
      // full block (https://symbl.cc/en/2588/)
      ctx.fillRect(x, y, BLOCK_H_RES, BLOCK_V_RES);
      break;

    case 0x25a0:
      // black square (https://symbl.cc/en/25A0/)
      ctx.fillRect(x, y + unitY * 2, BLOCK_H_RES, unitY * 4);
      break;

    case 0x2589:
      // left seven eighths block (https://symbl.cc/en/2589/)
      ctx.fillRect(x, y, unitX * 7, BLOCK_V_RES);
      break;

    case 0x258a:
      // left three quarters block (https://symbl.cc/en/258A/)
      ctx.fillRect(x, y, unitX * 6, BLOCK_V_RES);
      break;

    case 0x258b:
      // left five eighths block (https://symbl.cc/en/258B/)
      ctx.fillRect(x, y, unitX * 5, BLOCK_V_RES);
      break;

    case 0x258c:
      // left half block (https://symbl.cc/en/258C/)
      ctx.fillRect(x, y, halfX, BLOCK_V_RES);
      break;

    case 0x258d:
      // left three eighths block (https://symbl.cc/en/258D/)
      ctx.fillRect(x, y, unitX * 3, BLOCK_V_RES);
      break;

    case 0x258e:
      // left one quarter block (https://symbl.cc/en/258E/)
      ctx.fillRect(x, y, unitX * 2, BLOCK_V_RES);
      break;

    case 0x258f:
      // left one eighth block (https://symbl.cc/en/258F/)
      ctx.fillRect(x, y, unitX, BLOCK_V_RES);
      break;

    case 0x2590:
      // right half block (https://symbl.cc/en/2590/)
      ctx.fillRect(x + halfX, y, halfX, BLOCK_V_RES);
      break;

    case 0x2591:
      // light shade (https://symbl.cc/en/2591/)
      ctx.save();
      ctx.globalAlpha = 0.25;
      ctx.fillRect(x, y, BLOCK_H_RES, BLOCK_V_RES);
      ctx.restore();
      break;

    case 0x2592:
      // medium shade (https://symbl.cc/en/2592/)
      ctx.save();
      ctx.globalAlpha = 0.5;
      ctx.fillRect(x, y, BLOCK_H_RES, BLOCK_V_RES);
      ctx.restore();
      break;

    case 0x2593:
      // dark shade (https://symbl.cc/en/2593/)
      ctx.save();
      ctx.globalAlpha = 0.75;
      ctx.fillRect(x, y, BLOCK_H_RES, BLOCK_V_RES);
      ctx.restore();
      break;

    case 0x2594:
      // upper one eighth block (https://symbl.cc/en/2594/)
      ctx.fillRect(x, y, BLOCK_H_RES, unitY);
      break;

    case 0x2595:
      // right one eighth block (https://symbl.cc/en/2595/)
      ctx.fillRect(x + unitX * 7, y, unitX, BLOCK_V_RES);
      break;

    case 0x2596:
      // quadrant lower left (https://symbl.cc/en/2596/)
      ctx.fillRect(x, y + halfY, halfX, halfY);
      break;

    case 0x2597:
      // quadrant lower right (https://symbl.cc/en/2597/)
      ctx.fillRect(x + halfX, y + halfY, halfX, halfY);
      break;

    case 0x2598:
      // quadrant upper left (https://symbl.cc/en/2598/)
      ctx.fillRect(x, y, halfX, halfY);
      break;

    case 0x2599:
      // quadrant upper left and lower left and lower right (https://symbl.cc/en/2599/)
      ctx.fillRect(x, y, halfX, BLOCK_V_RES);
      ctx.fillRect(x + halfX, y + halfY, halfX, halfY);
      break;

    case 0x259a:
      // quadrant upper left and lower right (https://symbl.cc/en/259A/)
      ctx.fillRect(x, y, halfX, halfY);
      ctx.fillRect(x + halfX, y + halfY, halfX, halfY);
      break;

    case 0x259b:
      // quadrant upper left and upper right and lower left (https://symbl.cc/en/259B/)
      ctx.fillRect(x, y, BLOCK_H_RES, halfY);
      ctx.fillRect(x, y + halfY, halfX, halfY);
      break;

    case 0x259c:
      // quadrant upper left and upper right and lower right (https://symbl.cc/en/259C/)
      ctx.fillRect(x, y, BLOCK_H_RES, halfY);
      ctx.fillRect(x + halfX, y + halfY, halfX, halfY);
      break;

    case 0x259d:
      // quadrant upper right (https://symbl.cc/en/259D/)
      ctx.fillRect(x + halfX, y, halfX, halfY);
      break;

    case 0x259e:
      // quadrant upper right and lower left (https://symbl.cc/en/259E/)
      ctx.fillRect(x + halfX, y, halfX, halfY);
      ctx.fillRect(x, y + halfY, halfX, halfY);
      break;

    case 0x259f:
      // quadrant upper right and lower left and lower right (https://symbl.cc/en/259F/)
      ctx.fillRect(x + halfX, y, halfX, BLOCK_V_RES);
      ctx.fillRect(x, y + halfY, halfX, halfY);
      break;

    case 0x1fb00:
      // sextant-1: upper left (https://symbl.cc/en/1FB00/)
      ctx.fillRect(x, y, sextantX, sextantY);
      break;

    case 0x1fb01:
      // sextant-2: upper right (https://symbl.cc/en/1FB01/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      break;

    case 0x1fb02:
      // sextant-12: upper one third (https://symbl.cc/en/1FB02/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      break;

    case 0x1fb03:
      // sextant-3: middle left (https://symbl.cc/en/1FB03/)
      ctx.fillRect(x, y + sextantY, sextantX, sextantY);
      break;

    case 0x1fb04:
      // sextant-13: top-left and middle-left filled (https://symbl.cc/en/1FB04/)
      ctx.fillRect(x, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX, sextantY);
      break;

    case 0x1fb05:
      // sextant-23: upper right and middle left (https://symbl.cc/en/1FB05/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX, sextantY);
      break;

    case 0x1fb06:
      // sextant-123: upper one third and middle left (https://symbl.cc/en/1FB06/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX, sextantY);
      break;

    case 0x1fb07:
      // sextant-4: middle right (https://symbl.cc/en/1FB07/)
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      break;

    case 0x1fb08:
      // sextant-14: upper left and middle right (https://symbl.cc/en/1FB08/)
      ctx.fillRect(x, y, sextantX, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      break;

    case 0x1fb09:
      // sextant-24: top-right and middle-right filled (https://symbl.cc/en/1FB09/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      break;

    case 0x1fb0a:
      // sextant-124: upper one third and middle right (https://symbl.cc/en/1FB0A/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      break;

    case 0x1fb0b:
      // sextant-34: middle one third (https://symbl.cc/en/1FB0B/)
      ctx.fillRect(x, y + sextantY, sextantX * 2, sextantY);
      break;

    case 0x1fb0c:
      // sextant-134: upper left, middle left and middle right (https://symbl.cc/en/1FB0C/)
      ctx.fillRect(x, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX * 2, sextantY);
      break;

    case 0x1fb0d:
      // sextant-234: upper right and middle one third (https://symbl.cc/en/1FB0D/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX * 2, sextantY);
      break;

    case 0x1fb0e:
      // sextant-1234: top and middle rows filled (https://symbl.cc/en/1FB0E/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX * 2, sextantY);
      break;

    case 0x1fb0f:
      // sextant-5: lower left (https://symbl.cc/en/1FB0F/)
      ctx.fillRect(x, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb10:
      // sextant-15: upper left and lower left (https://symbl.cc/en/1FB10/)
      ctx.fillRect(x, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb11:
      // sextant-25: upper right and lower left (https://symbl.cc/en/1FB11/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb12:
      // sextant-125: upper one third and lower left (https://symbl.cc/en/1FB12/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb13:
      // sextant-35: middle left and lower left (https://symbl.cc/en/1FB13/)
      ctx.fillRect(x, y + sextantY, sextantX, sextantY * 2);
      break;

    case 0x1fb14:
      // sextant-235: upper right and left column lower two thirds (https://symbl.cc/en/1FB14/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX, sextantY * 2);
      break;

    case 0x1fb15:
      // sextant-1235: upper one third and left column lower two thirds (https://symbl.cc/en/1FB15/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX, sextantY * 2);
      break;

    case 0x1fb16:
      // sextant-45: middle right and lower left (https://symbl.cc/en/1FB16/)
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb17:
      // sextant-145: upper left, middle right and lower left (https://symbl.cc/en/1FB17/)
      ctx.fillRect(x, y, sextantX, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb18:
      // sextant-245: right column upper two thirds and lower left (https://symbl.cc/en/1FB18/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY * 2);
      ctx.fillRect(x, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb19:
      // sextant-1245: upper one third, middle right and lower left (https://symbl.cc/en/1FB19/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb1a:
      // sextant-345: middle one third and lower left (https://symbl.cc/en/1FB1A/)
      ctx.fillRect(x, y + sextantY, sextantX * 2, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb1b:
      // sextant-1345: left column and middle right (https://symbl.cc/en/1FB1B/)
      ctx.fillRect(x, y, sextantX, sextantY * 3);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      break;

    case 0x1fb1c:
      // sextant-2345: upper right, middle one third and lower left (https://symbl.cc/en/1FB1C/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX * 2, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb1d:
      // sextant-12345: upper two thirds and lower left (https://symbl.cc/en/1FB1D/)
      ctx.fillRect(x, y, sextantX * 2, sextantY * 2);
      ctx.fillRect(x, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb1e:
      // sextant-6: lower right (https://symbl.cc/en/1FB1E/)
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb1f:
      // sextant-16: upper left and lower right (https://symbl.cc/en/1FB1F/)
      ctx.fillRect(x, y, sextantX, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb20:
      // sextant-26: upper right and lower right (https://symbl.cc/en/1FB20/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb21:
      // sextant-126: upper one third and lower right (https://symbl.cc/en/1FB21/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb22:
      // sextant-36: middle left and lower right (https://symbl.cc/en/1FB22/)
      ctx.fillRect(x, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb23:
      // sextant-136: upper left, middle left and lower right (https://symbl.cc/en/1FB23/)
      ctx.fillRect(x, y, sextantX, sextantY * 2);
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb24:
      // sextant-236: upper right, middle left and lower right (https://symbl.cc/en/1FB24/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb25:
      // sextant-1236: upper one third, middle left and lower right (https://symbl.cc/en/1FB25/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb26:
      // sextant-46: middle right and lower right (https://symbl.cc/en/1FB26/)
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY * 2);
      break;

    case 0x1fb27:
      // sextant-146: upper left and right column lower two thirds (https://symbl.cc/en/1FB27/)
      ctx.fillRect(x, y, sextantX, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY * 2);
      break;

    case 0x1fb28:
      // sextant-1246: upper one third and right column lower two thirds (https://symbl.cc/en/1FB28/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY * 2);
      break;

    case 0x1fb29:
      // sextant-346: middle one third and lower right (https://symbl.cc/en/1FB29/)
      ctx.fillRect(x, y + sextantY, sextantX * 2, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb2a:
      // sextant-1346: left column upper two thirds and right column lower two thirds (https://symbl.cc/en/1FB2A/)
      ctx.fillRect(x, y, sextantX, sextantY * 2);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY * 2);
      break;

    case 0x1fb2b:
      // sextant-2346: upper right, middle one third and lower right (https://symbl.cc/en/1FB2B/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX * 2, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb2c:
      // sextant-12346: upper two thirds and lower right (https://symbl.cc/en/1FB2C/)
      ctx.fillRect(x, y, sextantX * 2, sextantY * 2);
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb2d:
      // sextant-56: lower one third (https://symbl.cc/en/1FB2D/)
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb2e:
      // sextant-156: upper left and lower one third (https://symbl.cc/en/1FB2E/)
      ctx.fillRect(x, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb2f:
      // sextant-256: upper right and lower one third (https://symbl.cc/en/1FB2F/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb30:
      // sextant-1256: upper one third and lower one third (https://symbl.cc/en/1FB30/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb31:
      // sextant-356: middle left and lower one third (https://symbl.cc/en/1FB31/)
      ctx.fillRect(x, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb32:
      // sextant-1356: left column upper two thirds and lower one third (https://symbl.cc/en/1FB32/)
      ctx.fillRect(x, y, sextantX, sextantY * 2);
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb33:
      // sextant-2356: upper right, middle left and lower one third (https://symbl.cc/en/1FB33/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb34:
      // sextant-12356: upper one third, middle left and lower one third (https://symbl.cc/en/1FB34/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb35:
      // sextant-456: middle right and lower one third (https://symbl.cc/en/1FB35/)
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb36:
      // sextant-1456: upper left, middle right and lower one third (https://symbl.cc/en/1FB36/)
      ctx.fillRect(x, y, sextantX, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb37:
      // sextant-2456: right column upper two thirds and lower one third (https://symbl.cc/en/1FB37/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY * 2);
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb38:
      // sextant-12456: upper one third, middle right and lower one third (https://symbl.cc/en/1FB38/)
      ctx.fillRect(x, y, sextantX * 2, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY * 2, sextantX * 2, sextantY);
      break;

    case 0x1fb39:
      // sextant-3456: middle one third and lower one third (https://symbl.cc/en/1FB39/)
      ctx.fillRect(x, y + sextantY, sextantX * 2, sextantY * 2);
      break;

    case 0x1fb3a:
      // sextant-13456: left column and lower one third (https://symbl.cc/en/1FB3A/)
      ctx.fillRect(x, y, sextantX, sextantY * 3);
      ctx.fillRect(x + sextantX, y + sextantY, sextantX, sextantY);
      ctx.fillRect(x + sextantX, y + sextantY * 2, sextantX, sextantY);
      break;

    case 0x1fb3b:
      // sextant-23456: upper right and lower two thirds (https://symbl.cc/en/1FB3B/)
      ctx.fillRect(x + sextantX, y, sextantX, sextantY);
      ctx.fillRect(x, y + sextantY, sextantX * 2, sextantY * 2);
      break;

    default:
      break;
  }
}

