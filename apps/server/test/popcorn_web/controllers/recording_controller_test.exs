defmodule PopcornWeb.RecordingControllerTest do
  use PopcornWeb.ConnCase, async: true
  import Popcorn.Factory

  describe "show public recording as owner" do
    setup [:insert_public_recording, :authenticate_as_owner]

    test "JS via ID", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    test "JS via secret token", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.id}/iframe", 200)
    end

    test "IFRAME via secret token", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.secret_token}/iframe", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    test "TXT via ID", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    test "SVG via secret token", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :rsvg
    test "PNG via ID", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "GIF via ID", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    test "GIF via secret token", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end
  end

  describe "show public recording as other user" do
    setup [:insert_public_recording, :authenticate_as_other]

    test "JS via ID", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    test "JS via secret token", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.id}/iframe", 200)
    end

    test "IFRAME via secret token", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.secret_token}/iframe", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    test "TXT via ID", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    test "SVG via secret token", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :rsvg
    test "PNG via ID", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "GIF via ID", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    test "GIF via secret token", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end
  end

  describe "show public recording as guest" do
    setup [:insert_public_recording]

    test "JS via ID", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    test "JS via secret token", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.id}/iframe", 200)
    end

    test "IFRAME via secret token", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.secret_token}/iframe", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    test "TXT via ID", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    test "SVG via secret token", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :rsvg
    test "PNG via ID", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "GIF via ID", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.id}", 200)
    end

    test "GIF via secret token", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end
  end

  describe "show unlisted recording as owner" do
    setup [:insert_unlisted_recording, :authenticate_as_owner]

    test "JS via ID", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "JS via secret token", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.id}/iframe", 404)
    end

    test "IFRAME via secret token", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.secret_token}/iframe", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    test "TXT via ID", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "SVG via secret token", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :rsvg
    test "PNG via ID", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :rsvg
    test "GIF via ID", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :rsvg
    test "GIF via secret token", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end
  end

  describe "show unlisted recording as other user" do
    setup [:insert_unlisted_recording, :authenticate_as_other]

    test "JS via ID", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "JS via secret token", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.id}/iframe", 404)
    end

    test "IFRAME via secret token", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.secret_token}/iframe", 200)
    end

    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "TXT via ID", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "SVG via secret token", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "PNG via ID", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "GIF via ID", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "GIF via secret token", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end
  end

  describe "show unlisted recording as guest" do
    setup [:insert_unlisted_recording]

    test "JS via ID", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "JS via secret token", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.id}/iframe", 404)
    end

    test "IFRAME via secret token", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.secret_token}/iframe", 200)
    end

    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "TXT via ID", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "SVG via secret token", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "PNG via ID", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "GIF via ID", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "GIF via secret token", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end
  end

  describe "show private recording as owner" do
    setup [:insert_private_recording, :authenticate_as_owner]

    test "JS via ID", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "JS via secret token", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "IFRAME via ID", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.id}/iframe", 404)
    end

    test "IFRAME via secret token", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.secret_token}/iframe", 200)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :with_file
    test "TXT via ID", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :with_file
    test "TXT via secret token", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    test "SVG via ID", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "SVG via secret token", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :rsvg
    test "PNG via ID", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :rsvg
    test "PNG via secret token", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end

    @tag :rsvg
    test "GIF via ID", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag :rsvg
    test "GIF via secret token", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.secret_token}", 200)
    end
  end

  describe "show private recording as other user" do
    setup [:insert_private_recording, :authenticate_as_other]

    test "JS via ID", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "JS via secret token", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    test "IFRAME via ID", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.id}/iframe", 404)
    end

    test "IFRAME via secret token", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.secret_token}/iframe", 403)
    end

    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    test "TXT via ID", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "TXT via secret token", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    test "SVG via ID", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "SVG via secret token", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    test "PNG via ID", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "PNG via secret token", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    test "GIF via ID", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "GIF via secret token", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end
  end

  describe "show private recording as guest" do
    setup [:insert_private_recording]

    test "JS via ID", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "JS via secret token", %{conn: conn, popcast: popcast} do
      test_js_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    test "IFRAME via ID", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.id}/iframe", 404)
    end

    test "IFRAME via secret token", %{conn: conn, popcast: popcast} do
      test_iframe_response(conn, ~p"/a/#{popcast.secret_token}/iframe", 403)
    end

    @tag version: 1
    test "CAST v1 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag version: 1
    test "CAST v1 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v1_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    @tag version: 2
    test "CAST v2 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag version: 2
    test "CAST v2 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v2_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    @tag version: 3
    test "CAST v3 via ID", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    @tag version: 3
    test "CAST v3 via secret token", %{conn: conn, popcast: popcast} do
      test_cast_v3_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    test "TXT via ID", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "TXT via secret token", %{conn: conn, popcast: popcast} do
      test_txt_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    test "SVG via ID", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "SVG via secret token", %{conn: conn, popcast: popcast} do
      test_svg_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    test "PNG via ID", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "PNG via secret token", %{conn: conn, popcast: popcast} do
      test_png_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end

    test "GIF via ID", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.id}", 404)
    end

    test "GIF via secret token", %{conn: conn, popcast: popcast} do
      test_gif_response(conn, ~p"/a/#{popcast.secret_token}", 403)
    end
  end

  describe "show non-existing recording" do
    test "JS", %{conn: conn} do
      test_js_response(conn, ~p"/a/99999999", 404)
      test_js_response(conn, ~p"/a/nopenopenope", 404)
    end

    test "TXT", %{conn: conn} do
      url = ~p"/a/99999999"

      conn_2 = get(conn, url <> ".txt")

      assert text_response(conn_2, 404)

      conn_2 =
        conn
        |> put_req_header("accept", "text/plain")
        |> get(url)

      assert text_response(conn_2, 404)
    end
  end

  describe "deleting" do
    test "requires author", %{conn: conn} do
      user = insert(:user)
      popcast = insert(:popcast, user: user)
      conn = log_in(conn, insert(:user))

      conn = delete(conn, ~p"/a/#{popcast}")

      assert html_response(conn, 403)
    end
  end

  describe "unauthenticated write" do
    test "HTML request redirects to login", %{conn: conn} do
      popcast = insert(:popcast)

      conn = delete(conn, ~p"/a/#{popcast}")

      assert redirected_to(conn, 302) == "/login/new"
    end

    # Non-HTML formats can't fetch flash in the popcast pipeline, and a login
    # redirect makes no sense for them; require_current_user responds with 401
    # rather than crashing.
    test "PUT with non-HTML format responds with 401", %{conn: conn} do
      conn = put(conn, "/a/testing-put.txt")

      assert response(conn, 401)
    end

    test "DELETE with non-HTML format responds with 401", %{conn: conn} do
      conn = delete(conn, "/a/testing-delete.json")

      assert response(conn, 401)
    end
  end

  describe "SVG cache-control" do
    setup [:insert_public_recording]

    test "uses 1 year max-age only for matching v param", %{conn: conn, popcast: popcast} do
      cache_key = PopcornWeb.RecordingSVG.svg_cache_key(popcast)

      conn = get(conn, ~p"/a/#{popcast.id}" <> ".svg?v=" <> cache_key)

      assert ["public, max-age=31536000, must-revalidate"] =
               get_resp_header(conn, "cache-control")
    end

    test "uses 1 hour max-age for non-matching v param", %{conn: conn, popcast: popcast} do
      conn = get(conn, ~p"/a/#{popcast.id}" <> ".svg?v=stale")

      assert ["public, max-age=3600, must-revalidate"] = get_resp_header(conn, "cache-control")
    end
  end

  describe "PNG cache-control" do
    setup [:insert_public_recording]

    test "uses 1 hour max-age and etag", %{conn: conn, popcast: popcast} do
      conn = get(conn, ~p"/a/#{popcast.id}" <> ".png")

      assert ["public, max-age=3600, must-revalidate"] = get_resp_header(conn, "cache-control")
      assert [_etag] = get_resp_header(conn, "etag")
    end

    test "returns 304 for matching if-none-match", %{conn: conn, popcast: popcast} do
      conn = get(conn, ~p"/a/#{popcast.id}" <> ".png")
      [etag] = get_resp_header(conn, "etag")

      conn =
        build_conn()
        |> put_req_header("if-none-match", etag)
        |> get(~p"/a/#{popcast.id}" <> ".png")

      assert response(conn, 304) == ""
    end
  end

  describe "cast response encoding" do
    setup [:insert_public_recording]

    @tag :with_file
    test "serves plain .pop/.json when gzip is not requested", %{
      conn: conn,
      popcast: popcast
    } do
      conn_1 = get(conn, ~p"/a/#{popcast.id}" <> ".pop")
      body_1 = popcast_response(conn_1, 200)

      assert ["accept-encoding"] = get_resp_header(conn_1, "vary")
      assert [] == get_resp_header(conn_1, "content-encoding")
      assert ~s({"version": 2) <> _ = body_1

      conn_2 = get(conn, ~p"/a/#{popcast.id}" <> ".json")
      body_2 = popcast_response(conn_2, 200)

      assert ["accept-encoding"] = get_resp_header(conn_2, "vary")
      assert [] == get_resp_header(conn_2, "content-encoding")
      assert ~s({"version": 2) <> _ = body_2
    end

    @tag :with_file
    test "serves gzip .pop/.json when accept-encoding includes gzip", %{
      conn: conn,
      popcast: popcast
    } do
      conn_1 =
        conn
        |> put_req_header("accept-encoding", "gzip, deflate")
        |> get(~p"/a/#{popcast.id}" <> ".pop")

      gzip_body_1 = popcast_response(conn_1, 200)

      assert ["accept-encoding"] = get_resp_header(conn_1, "vary")
      assert ["gzip"] = get_resp_header(conn_1, "content-encoding")
      assert ~s({"version": 2) <> _ = :zlib.gunzip(gzip_body_1)

      conn_2 =
        conn
        |> put_req_header("accept-encoding", "br, gzip")
        |> get(~p"/a/#{popcast.id}" <> ".json")

      gzip_body_2 = popcast_response(conn_2, 200)

      assert ["accept-encoding"] = get_resp_header(conn_2, "vary")
      assert ["gzip"] = get_resp_header(conn_2, "content-encoding")
      assert ~s({"version": 2) <> _ = :zlib.gunzip(gzip_body_2)
    end

    @tag :with_file
    test "serves zstd .pop/.json when accept-encoding includes zstd", %{
      conn: conn,
      popcast: popcast
    } do
      conn_1 =
        conn
        |> put_req_header("accept-encoding", "zstd")
        |> get(~p"/a/#{popcast.id}" <> ".pop")

      zstd_body_1 = popcast_response(conn_1, 200)

      assert ["accept-encoding"] = get_resp_header(conn_1, "vary")
      assert ["zstd"] = get_resp_header(conn_1, "content-encoding")
      assert ~s({"version": 2) <> _ = zstd_decompress(zstd_body_1)

      conn_2 =
        conn
        |> put_req_header("accept-encoding", "br, zstd")
        |> get(~p"/a/#{popcast.id}" <> ".json")

      zstd_body_2 = popcast_response(conn_2, 200)

      assert ["accept-encoding"] = get_resp_header(conn_2, "vary")
      assert ["zstd"] = get_resp_header(conn_2, "content-encoding")
      assert ~s({"version": 2) <> _ = zstd_decompress(zstd_body_2)
    end

    @tag :with_file
    test "prefers zstd over gzip when both are acceptable", %{
      conn: conn,
      popcast: popcast
    } do
      conn =
        conn
        |> put_req_header("accept-encoding", "gzip, zstd")
        |> get(~p"/a/#{popcast.id}" <> ".pop")

      zstd_body = popcast_response(conn, 200)

      assert ["zstd"] = get_resp_header(conn, "content-encoding")
      assert ~s({"version": 2) <> _ = zstd_decompress(zstd_body)
    end

    @tag :with_file
    test "treats q=0 as unacceptable", %{conn: conn, popcast: popcast} do
      gzip_conn =
        conn
        |> put_req_header("accept-encoding", "zstd;q=0, gzip;q=1")
        |> get(~p"/a/#{popcast.id}" <> ".pop")

      gzip_body = popcast_response(gzip_conn, 200)

      assert ["gzip"] = get_resp_header(gzip_conn, "content-encoding")
      assert ~s({"version": 2) <> _ = :zlib.gunzip(gzip_body)

      plain_conn =
        conn
        |> put_req_header("accept-encoding", "zstd;q=0, gzip;q=0")
        |> get(~p"/a/#{popcast.id}" <> ".json")

      plain_body = popcast_response(plain_conn, 200)

      assert [] == get_resp_header(plain_conn, "content-encoding")
      assert ~s({"version": 2) <> _ = plain_body
    end

    @tag :with_zstd_file
    test "serves plain .pop/.json when stored file is zstd-compressed and encoding is not requested",
         %{
           conn: conn,
           popcast: popcast
         } do
      conn_1 = get(conn, ~p"/a/#{popcast.id}" <> ".pop")
      body_1 = popcast_response(conn_1, 200)

      assert ["accept-encoding"] = get_resp_header(conn_1, "vary")
      assert [] == get_resp_header(conn_1, "content-encoding")
      assert ~s({"version": 2) <> _ = body_1

      conn_2 = get(conn, ~p"/a/#{popcast.id}" <> ".json")
      body_2 = popcast_response(conn_2, 200)

      assert ["accept-encoding"] = get_resp_header(conn_2, "vary")
      assert [] == get_resp_header(conn_2, "content-encoding")
      assert ~s({"version": 2) <> _ = body_2
    end

    @tag :with_zstd_file
    test "serves gzip .pop/.json when stored file is zstd-compressed and accept-encoding includes gzip",
         %{conn: conn, popcast: popcast} do
      conn_1 =
        conn
        |> put_req_header("accept-encoding", "gzip, deflate")
        |> get(~p"/a/#{popcast.id}" <> ".pop")

      gzip_body_1 = popcast_response(conn_1, 200)

      assert ["accept-encoding"] = get_resp_header(conn_1, "vary")
      assert ["gzip"] = get_resp_header(conn_1, "content-encoding")
      assert ~s({"version": 2) <> _ = :zlib.gunzip(gzip_body_1)

      conn_2 =
        conn
        |> put_req_header("accept-encoding", "br, gzip")
        |> get(~p"/a/#{popcast.id}" <> ".json")

      gzip_body_2 = popcast_response(conn_2, 200)

      assert ["accept-encoding"] = get_resp_header(conn_2, "vary")
      assert ["gzip"] = get_resp_header(conn_2, "content-encoding")
      assert ~s({"version": 2) <> _ = :zlib.gunzip(gzip_body_2)
    end

    @tag :with_zstd_file
    test "serves stored zstd .pop/.json directly when zstd is acceptable",
         %{conn: conn, popcast: popcast} do
      stored_body =
        popcast
        |> Popcorn.Recordings.get_cast_path!()
        |> File.read!()

      conn =
        conn
        |> put_req_header("accept-encoding", "zstd, gzip")
        |> get(~p"/a/#{popcast.id}" <> ".pop")

      zstd_body = popcast_response(conn, 200)

      assert ["accept-encoding"] = get_resp_header(conn, "vary")
      assert ["zstd"] = get_resp_header(conn, "content-encoding")
      assert zstd_body == stored_body
      assert ~s({"version": 2) <> _ = zstd_decompress(zstd_body)
    end
  end

  describe "txt response encoding" do
    setup [:insert_public_recording]

    @tag :with_file
    test "serves plain .txt when encoding is not requested", %{conn: conn, popcast: popcast} do
      conn = get(conn, ~p"/a/#{popcast.id}" <> ".txt")
      plain_body = response(conn, 200)

      assert ["accept-encoding"] = get_resp_header(conn, "vary")
      assert [] == get_resp_header(conn, "content-encoding")
      assert List.first(get_resp_header(conn, "content-type")) == "text/plain"

      assert List.first(get_resp_header(conn, "content-disposition")) ==
               "attachment; filename=#{popcast.id}.txt"

      assert is_binary(plain_body)
    end

    @tag :with_file
    test "serves gzip .txt when accept-encoding includes gzip", %{
      conn: conn,
      popcast: popcast
    } do
      plain_conn = get(conn, ~p"/a/#{popcast.id}" <> ".txt")
      plain_body = response(plain_conn, 200)

      gzip_conn =
        conn
        |> put_req_header("accept-encoding", "gzip, br")
        |> get(~p"/a/#{popcast.id}" <> ".txt")

      gzip_body = response(gzip_conn, 200)

      assert ["accept-encoding"] = get_resp_header(gzip_conn, "vary")
      assert ["gzip"] = get_resp_header(gzip_conn, "content-encoding")
      assert List.first(get_resp_header(gzip_conn, "content-type")) == "text/plain"

      assert List.first(get_resp_header(gzip_conn, "content-disposition")) ==
               "attachment; filename=#{popcast.id}.txt"

      assert :zlib.gunzip(gzip_body) == plain_body
    end

    @tag :with_file
    test "serves zstd .txt when accept-encoding includes zstd", %{
      conn: conn,
      popcast: popcast
    } do
      plain_conn = get(conn, ~p"/a/#{popcast.id}" <> ".txt")
      plain_body = response(plain_conn, 200)

      zstd_conn =
        conn
        |> put_req_header("accept-encoding", "zstd")
        |> get(~p"/a/#{popcast.id}" <> ".txt")

      zstd_body = response(zstd_conn, 200)

      assert ["accept-encoding"] = get_resp_header(zstd_conn, "vary")
      assert ["zstd"] = get_resp_header(zstd_conn, "content-encoding")
      assert List.first(get_resp_header(zstd_conn, "content-type")) == "text/plain"

      assert List.first(get_resp_header(zstd_conn, "content-disposition")) ==
               "attachment; filename=#{popcast.id}.txt"

      assert zstd_decompress(zstd_body) == plain_body
    end

    @tag :with_file
    test "prefers zstd over gzip for .txt and treats q=0 as unacceptable", %{
      conn: conn,
      popcast: popcast
    } do
      zstd_conn =
        conn
        |> put_req_header("accept-encoding", "gzip, zstd")
        |> get(~p"/a/#{popcast.id}" <> ".txt")

      assert ["zstd"] = get_resp_header(zstd_conn, "content-encoding")

      gzip_conn =
        conn
        |> put_req_header("accept-encoding", "zstd;q=0, gzip;q=1")
        |> get(~p"/a/#{popcast.id}" <> ".txt")

      assert ["gzip"] = get_resp_header(gzip_conn, "content-encoding")
    end
  end

  describe "svg response encoding" do
    setup [:insert_public_recording]

    test "serves plain .svg when encoding is not requested", %{conn: conn, popcast: popcast} do
      conn = get(conn, ~p"/a/#{popcast.id}" <> ".svg")
      plain_body = response(conn, 200)

      assert ["accept-encoding"] = get_resp_header(conn, "vary")
      assert [] == get_resp_header(conn, "content-encoding")
      assert response_content_type(conn, :svg)
      assert plain_body =~ "foo"
      assert plain_body =~ "bar"
    end

    test "serves gzip .svg when accept-encoding includes gzip", %{
      conn: conn,
      popcast: popcast
    } do
      plain_conn = get(conn, ~p"/a/#{popcast.id}" <> ".svg")
      plain_body = response(plain_conn, 200)

      gzip_conn =
        conn
        |> put_req_header("accept-encoding", "deflate, gzip")
        |> get(~p"/a/#{popcast.id}" <> ".svg")

      gzip_body = response(gzip_conn, 200)

      assert ["accept-encoding"] = get_resp_header(gzip_conn, "vary")
      assert ["gzip"] = get_resp_header(gzip_conn, "content-encoding")
      assert response_content_type(gzip_conn, :svg)
      assert :zlib.gunzip(gzip_body) == plain_body
    end

    test "serves zstd .svg when accept-encoding includes zstd", %{
      conn: conn,
      popcast: popcast
    } do
      plain_conn = get(conn, ~p"/a/#{popcast.id}" <> ".svg")
      plain_body = response(plain_conn, 200)

      zstd_conn =
        conn
        |> put_req_header("accept-encoding", "zstd")
        |> get(~p"/a/#{popcast.id}" <> ".svg")

      zstd_body = response(zstd_conn, 200)

      assert ["accept-encoding"] = get_resp_header(zstd_conn, "vary")
      assert ["zstd"] = get_resp_header(zstd_conn, "content-encoding")
      assert response_content_type(zstd_conn, :svg)
      assert zstd_decompress(zstd_body) == plain_body
    end

    test "prefers zstd over gzip for .svg and treats q=0 as unacceptable", %{
      conn: conn,
      popcast: popcast
    } do
      zstd_conn =
        conn
        |> put_req_header("accept-encoding", "gzip, zstd")
        |> get(~p"/a/#{popcast.id}" <> ".svg")

      assert ["zstd"] = get_resp_header(zstd_conn, "content-encoding")

      gzip_conn =
        conn
        |> put_req_header("accept-encoding", "zstd;q=0, gzip;q=1")
        |> get(~p"/a/#{popcast.id}" <> ".svg")

      assert ["gzip"] = get_resp_header(gzip_conn, "content-encoding")
    end
  end

  defp insert_public_recording(context) do
    [popcast: insert_recording(:public, context)]
  end

  defp insert_unlisted_recording(context) do
    [popcast: insert_recording(:unlisted, context)]
  end

  defp insert_private_recording(context) do
    [popcast: insert_recording(:private, context)]
  end

  defp insert_recording(visibility, context) do
    version = Map.get(context, :version, 2)
    with_file = Map.get(context, :with_file, false)
    with_zstd_file = Map.get(context, :with_zstd_file, false)

    attrs = [
      visibility: visibility,
      compressed: with_zstd_file
    ]

    attrs =
      if with_zstd_file do
        Keyword.put(attrs, :path, zstd_recording_path(version))
      else
        attrs
      end

    popcast = insert(:"popcast_v#{version}", attrs)

    cond do
      with_zstd_file -> with_zstd_file(popcast)
      with_file -> with_file(popcast)
      true -> popcast
    end
  end

  defp authenticate_as_owner(%{conn: conn, popcast: popcast}) do
    [conn: log_in(conn, popcast.user)]
  end

  defp authenticate_as_other(%{conn: conn}) do
    [conn: log_in(conn, insert(:user))]
  end

  defp test_js_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".js")

    assert response(conn_2, 200)
    assert response_content_type(conn_2, :js)

    conn_2 =
      conn
      |> put_req_header("accept", "application/javascript")
      |> get(url)

    assert response(conn_2, 200)
    assert response_content_type(conn_2, :js)
  end

  defp test_js_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".js")

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "application/javascript")
      |> get(url)

    assert text_response(conn_2, status)
  end

  defp test_iframe_response(conn, url, 200) do
    conn_2 =
      conn
      |> put_req_header("accept", "*/*")
      |> get(url)

    assert html_response(conn_2, 200) =~ "createPlayer"

    conn_2 =
      conn
      |> put_req_header("accept", "text/html")
      |> get(url)

    assert html_response(conn_2, 200) =~ "createPlayer"
  end

  defp test_iframe_response(conn, url, status) when status >= 400 do
    conn = get(conn, url)

    assert html_response(conn, status)
  end

  defp test_cast_v1_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".pop")

    assert json = popcast_response(conn_2, 200)
    assert %{"version" => 1} = Jason.decode!(json)

    conn_2 = get(conn, url <> ".json")

    assert json = popcast_response(conn_2, 200)
    assert %{"version" => 1} = Jason.decode!(json)
  end

  defp test_cast_v1_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".pop")

    assert text_response(conn_2, status)

    conn_2 = get(conn, url <> ".json")

    assert json_response(conn_2, status)
  end

  defp test_cast_v2_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".pop")

    assert ~s({"version": 2) <> _ = popcast_response(conn_2, 200)
  end

  defp test_cast_v2_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".pop")

    assert text_response(conn_2, status)
  end

  defp test_cast_v3_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".pop")

    assert ~s({"version": 3) <> _ = popcast_response(conn_2, 200)
  end

  defp test_cast_v3_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".pop")

    assert text_response(conn_2, status)
  end

  defp test_txt_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".txt")

    assert text_response(conn_2, 200)

    conn_2 =
      conn
      |> put_req_header("accept", "text/plain")
      |> get(url)

    assert text_response(conn_2, 200)
  end

  defp test_txt_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".txt")

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "text/plain")
      |> get(url)

    assert text_response(conn_2, status)
  end

  defp test_svg_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".svg")

    body = response(conn_2, 200)
    assert response_content_type(conn_2, :svg)

    # Verify snapshot content is rendered (factory creates snapshot with "foo" and "bar")
    assert body =~ "foo"
    assert body =~ "bar"

    conn_2 =
      conn
      |> put_req_header("accept", "image/svg+xml")
      |> get(url)

    assert response(conn_2, 200)
    assert response_content_type(conn_2, :svg)

    conn_2 =
      conn
      |> put_req_header("accept", "image/*")
      |> get(url)

    assert response(conn_2, 200)
    assert response_content_type(conn_2, :svg)

    conn_2 = get(conn, url <> ".svg?f=t")

    assert response(conn_2, 200)
    assert response_content_type(conn_2, :svg)
  end

  defp test_svg_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".svg")

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "image/svg+xml")
      |> get(url)

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "image/*")
      |> get(url)

    assert text_response(conn_2, status)

    conn_2 = get(conn, url <> ".svg?f=t")

    assert text_response(conn_2, status)
  end

  defp test_png_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".png")

    assert png_response(conn_2, 200)

    conn_2 =
      conn
      |> put_req_header("accept", "image/png")
      |> get(url)

    assert png_response(conn_2, 200)
  end

  defp test_png_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".png")

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "image/png")
      |> get(url)

    assert text_response(conn_2, status)
  end

  defp test_gif_response(conn, url, 200) do
    conn = get(conn, url <> ".gif")

    assert html_response(conn, 200) =~ "GIF"
  end

  defp test_gif_response(conn, url, status) when status >= 400 do
    conn = get(conn, url <> ".gif")

    assert text_response(conn, status)
  end

  defp popcast_response(conn, 200) do
    body = response(conn, 200)
    assert List.first(get_resp_header(conn, "content-type")) == "application/x-popcast"

    body
  end

  defp zstd_recording_path(1), do: "recordings/#{System.unique_integer([:positive])}.json.zst"
  defp zstd_recording_path(_), do: "recordings/#{System.unique_integer([:positive])}.pop.zst"

  defp zstd_decompress(data) do
    data
    |> :zstd.decompress()
    |> IO.iodata_to_binary()
  end

  defp png_response(conn, status) do
    _ = response(conn, status)
    assert response_content_type(conn, :png)

    true
  end

  defp with_zstd_file(popcast, filename \\ nil)

  defp with_zstd_file(popcast, nil) do
    filename =
      case popcast.version do
        1 -> "welcome.json"
        2 -> "welcome.pop"
        3 -> "3/full.pop"
      end

    with_zstd_file(popcast, filename)
  end

  defp with_zstd_file(popcast, filename) do
    path = Briefly.create!()
    File.write!(path, :zstd.compress(File.read!("test/fixtures/#{filename}")))
    :ok = Popcorn.FileStore.put_file(popcast.path, path, "application/x-popcast")

    popcast
  end
end
