defmodule PopcornWeb.RecordingControllerTest do
  use PopcornWeb.ConnCase, async: true
  use PopcornWeb.RecordingControllerHelpers
  import Popcorn.Factory

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
end
