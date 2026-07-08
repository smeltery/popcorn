defmodule PopcornWeb.RecordingControllerHelpers do
  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Plug.Conn
  import Popcorn.Factory

  @endpoint PopcornWeb.Endpoint

  defmacro __using__(_opts) do
    quote do
      import PopcornWeb.RecordingControllerHelpers,
        except: [
          authenticate_as_other: 1,
          authenticate_as_owner: 1,
          insert_private_recording: 1,
          insert_public_recording: 1,
          insert_recording: 2,
          insert_unlisted_recording: 1,
          log_in: 2
        ]

      defp insert_public_recording(context) do
        PopcornWeb.RecordingControllerHelpers.insert_public_recording(context)
      end

      defp insert_unlisted_recording(context) do
        PopcornWeb.RecordingControllerHelpers.insert_unlisted_recording(context)
      end

      defp insert_private_recording(context) do
        PopcornWeb.RecordingControllerHelpers.insert_private_recording(context)
      end

      defp authenticate_as_owner(context) do
        PopcornWeb.RecordingControllerHelpers.authenticate_as_owner(context)
      end

      defp authenticate_as_other(context) do
        PopcornWeb.RecordingControllerHelpers.authenticate_as_other(context)
      end
    end
  end

  def insert_public_recording(context) do
    [popcast: insert_recording(:public, context)]
  end

  def insert_unlisted_recording(context) do
    [popcast: insert_recording(:unlisted, context)]
  end

  def insert_private_recording(context) do
    [popcast: insert_recording(:private, context)]
  end

  def insert_recording(visibility, context) do
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

  def authenticate_as_owner(%{conn: conn, popcast: popcast}) do
    [conn: log_in(conn, popcast.user)]
  end

  def authenticate_as_other(%{conn: conn}) do
    [conn: log_in(conn, insert(:user))]
  end

  def log_in(conn, user) do
    init_test_session(conn, %{user_id: user.id})
  end

  def test_js_response(conn, url, 200) do
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

  def test_js_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".js")

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "application/javascript")
      |> get(url)

    assert text_response(conn_2, status)
  end

  def test_iframe_response(conn, url, 200) do
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

  def test_iframe_response(conn, url, status) when status >= 400 do
    conn = get(conn, url)

    assert html_response(conn, status)
  end

  def test_cast_v1_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".pop")

    assert json = popcast_response(conn_2, 200)
    assert %{"version" => 1} = Jason.decode!(json)

    conn_2 = get(conn, url <> ".json")

    assert json = popcast_response(conn_2, 200)
    assert %{"version" => 1} = Jason.decode!(json)
  end

  def test_cast_v1_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".pop")

    assert text_response(conn_2, status)

    conn_2 = get(conn, url <> ".json")

    assert json_response(conn_2, status)
  end

  def test_cast_v2_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".pop")

    assert ~s({"version": 2) <> _ = popcast_response(conn_2, 200)
  end

  def test_cast_v2_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".pop")

    assert text_response(conn_2, status)
  end

  def test_cast_v3_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".pop")

    assert ~s({"version": 3) <> _ = popcast_response(conn_2, 200)
  end

  def test_cast_v3_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".pop")

    assert text_response(conn_2, status)
  end

  def test_txt_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".txt")

    assert text_response(conn_2, 200)

    conn_2 =
      conn
      |> put_req_header("accept", "text/plain")
      |> get(url)

    assert text_response(conn_2, 200)
  end

  def test_txt_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".txt")

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "text/plain")
      |> get(url)

    assert text_response(conn_2, status)
  end

  def test_svg_response(conn, url, 200) do
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

  def test_svg_response(conn, url, status) when status >= 400 do
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

  def test_png_response(conn, url, 200) do
    conn_2 = get(conn, url <> ".png")

    assert png_response(conn_2, 200)

    conn_2 =
      conn
      |> put_req_header("accept", "image/png")
      |> get(url)

    assert png_response(conn_2, 200)
  end

  def test_png_response(conn, url, status) when status >= 400 do
    conn_2 = get(conn, url <> ".png")

    assert text_response(conn_2, status)

    conn_2 =
      conn
      |> put_req_header("accept", "image/png")
      |> get(url)

    assert text_response(conn_2, status)
  end

  def test_gif_response(conn, url, 200) do
    conn = get(conn, url <> ".gif")

    assert html_response(conn, 200) =~ "GIF"
  end

  def test_gif_response(conn, url, status) when status >= 400 do
    conn = get(conn, url <> ".gif")

    assert text_response(conn, status)
  end

  def popcast_response(conn, 200) do
    body = response(conn, 200)
    assert List.first(get_resp_header(conn, "content-type")) == "application/x-popcast"

    body
  end

  def zstd_recording_path(1), do: "recordings/#{System.unique_integer([:positive])}.json.zst"
  def zstd_recording_path(_), do: "recordings/#{System.unique_integer([:positive])}.pop.zst"

  def zstd_decompress(data) do
    data
    |> :zstd.decompress()
    |> IO.iodata_to_binary()
  end

  def png_response(conn, status) do
    _ = response(conn, status)
    assert response_content_type(conn, :png)

    true
  end

  def with_zstd_file(popcast, filename \\ nil)

  def with_zstd_file(popcast, nil) do
    filename =
      case popcast.version do
        1 -> "welcome.json"
        2 -> "welcome.pop"
        3 -> "3/full.pop"
      end

    with_zstd_file(popcast, filename)
  end

  def with_zstd_file(popcast, filename) do
    path = Briefly.create!()
    File.write!(path, :zstd.compress(File.read!("test/fixtures/#{filename}")))
    :ok = Popcorn.FileStore.put_file(popcast.path, path, "application/x-popcast")

    popcast
  end
end
