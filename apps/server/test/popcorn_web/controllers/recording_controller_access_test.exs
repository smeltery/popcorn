defmodule PopcornWeb.RecordingControllerAccessTest do
  use PopcornWeb.ConnCase, async: true
  use PopcornWeb.RecordingControllerHelpers

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
end
