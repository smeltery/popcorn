defmodule PopcornWeb.RecordingController do
  use PopcornWeb, :controller
  alias Popcorn.{FileCache, Gzip, Recordings, Zstd}
  alias Popcorn.Recordings.Popcast
  alias Popcorn.Recordings.Query, as: RecordingQuery
  alias PopcornWeb.{Authorization, PlayerOpts, PngGenerator, RecordingSVG}
  alias PopcornWeb.FallbackController

  plug :require_current_user when action in [:edit, :update, :delete]
  plug :load_and_authorize_popcast when action in [:show, :edit, :update, :delete, :iframe]
  plug :redirect_to_canonical_path when action == :show
  @encoding_chunk_size 64 * 1024

  def show(conn, _params) do
    do_show(conn, get_format(conn), conn.assigns.popcast)
  end

  def do_show(conn, "html", popcast) do
    if popcast.archived_at do
      conn
      |> put_status(410)
      |> render(:deleted, ttl: Popcorn.unclaimed_recording_ttl())
    else
      current_user = conn.assigns.current_user
      self = !!(current_user && current_user.id == popcast.user_id)
      other_popcasts = fetch_other_popcasts(popcast, current_user)

      render(conn, :show,
        page_title: Recordings.title(popcast),
        popcast: popcast,
        self: self,
        player_opts: player_opts(conn.params),
        actions: popcast_actions(popcast, current_user),
        view_count_url: build_view_count_url(conn, popcast),
        other_popcasts: other_popcasts
      )
    end
  end

  def do_show(conn, format, popcast) when format in ["json", "pop"] do
    if popcast.archived_at do
      send_resp(conn, 410, "")
    else
      filename = attachment_filename(popcast, conn.params)
      encoding = preferred_response_encoding(conn)

      case get_cast_path(popcast, encoding) do
        {:ok, path} ->
          conn
          |> put_resp_header("content-type", "application/x-popcast")
          |> put_resp_header("access-control-allow-origin", "*")
          |> put_resp_header("vary", "accept-encoding")
          |> maybe_put_content_encoding(encoding)
          |> put_content_disposition(filename)
          |> send_file(200, path)

        {:error, %FileCache.Error{type: :timeout}} ->
          conn
          |> put_resp_header("retry-after", "5")
          |> send_resp(503, "")

        {:error, error} ->
          raise error
      end
    end
  end

  @js_max_age 60

  def do_show(conn, "js", _popcast) do
    path = Application.app_dir(:popcorn, "priv/static/js/embed.js")

    conn
    |> put_resp_content_type("application/javascript")
    |> put_resp_header("cache-control", "public, max-age=#{@js_max_age}")
    |> send_file(200, path)
  end

  def do_show(conn, "txt", popcast) do
    if popcast.archived_at do
      conn
      |> put_status(410)
      |> text("This recording has been deleted\n")
    else
      encoding = preferred_response_encoding(conn)

      case get_txt_path(popcast, encoding) do
        {:ok, path} ->
          conn
          |> put_resp_header("content-type", "text/plain")
          |> put_resp_header("vary", "accept-encoding")
          |> maybe_put_content_encoding(encoding)
          |> put_resp_header("content-disposition", "attachment; filename=#{popcast.id}.txt")
          |> send_file(200, path)

        {:error, %FileCache.Error{type: :timeout}} ->
          conn
          |> put_resp_header("retry-after", "5")
          |> send_resp(503, "")

        {:error, error} ->
          raise error
      end
    end
  end

  def do_show(conn, "svg", popcast) do
    if popcast.archived_at do
      path = Application.app_dir(:popcorn, "priv/static/images/archived.png")

      conn
      |> put_status(410)
      |> put_resp_content_type("image/png")
      |> send_file(200, path)
    else
      cache_key = RecordingSVG.svg_cache_key(popcast)
      max_age = svg_max_age(conn.params, cache_key)
      encoding = preferred_response_encoding(conn)

      conn =
        conn
        |> put_resp_header("cache-control", "public, max-age=#{max_age}, must-revalidate")
        |> put_etag(cache_key)
        |> put_resp_header("access-control-allow-origin", "*")
        |> put_resp_header("vary", "accept-encoding")
        |> maybe_put_content_encoding(encoding)
        |> put_resp_content_type("image/svg+xml; charset=utf-8")

      if fresh?(conn) do
        conn
        |> send_resp(304, "")
        |> halt()
      else
        case get_svg_path(popcast, conn.params, cache_key, encoding) do
          {:ok, path} ->
            conn
            |> send_file(200, path)
            |> halt()

          {:error, %FileCache.Error{type: :timeout}} ->
            conn
            |> put_resp_header("retry-after", "5")
            |> send_resp(503, "")

          {:error, error} ->
            raise error
        end
      end
    end
  end

  @png_max_age 60 * 60
  @png_cache_timeout 45_000

  def do_show(conn, "png", popcast) do
    if popcast.archived_at do
      path = Application.app_dir(:popcorn, "priv/static/images/archived.png")

      conn
      |> put_status(410)
      |> put_resp_content_type("image/png")
      |> send_file(200, path)
    else
      cache_key = PngGenerator.png_cache_key(popcast)

      conn =
        conn
        |> put_resp_header("cache-control", "public, max-age=#{@png_max_age}, must-revalidate")
        |> put_etag(cache_key)
        |> put_resp_content_type("image/png")

      if fresh?(conn) do
        conn
        |> send_resp(304, "")
        |> halt()
      else
        case get_png_path(popcast, cache_key) do
          {:ok, path} ->
            conn
            |> send_file(200, path)
            |> halt()

          {:error, %FileCache.Error{type: :timeout}} ->
            conn
            |> put_resp_header("retry-after", "5")
            |> send_resp(503, "")

          {:error,
           %FileCache.Error{
             type: :generator_failed,
             reason: %PngGenerator.Error{retryable: true}
           }} ->
            conn
            |> put_resp_header("retry-after", "5")
            |> send_resp(503, "")

          {:error, error} ->
            raise error
        end
      end
    end
  end

  def do_show(conn, "gif", popcast) do
    if popcast.archived_at do
      send_resp(conn, 410, "")
    else
      conn
      |> put_layout("simple.html")
      |> render("gif.html",
        file_url: popcast_file_url(popcast),
        popcast_id: popcast.id
      )
    end
  end

  defp svg_max_age(%{"v" => v}, cache_key) when v == cache_key, do: 60 * 60 * 24 * 365
  defp svg_max_age(_params, _cache_key), do: 60 * 60

  defp get_cast_path(popcast, encoding) do
    with {:ok, path} <- Recordings.fetch_cast_path(popcast) do
      case {popcast.compressed, encoding} do
        {true, :zstd} ->
          {:ok, path}

        {true, :gzip} ->
          fetch_gzip_path(:pop_gz, popcast.id, path, :zstd)

        {true, :identity} ->
          fetch_plain_path(Recordings.cast_cache_bucket(false), popcast.id, path, :zstd)

        {false, :zstd} ->
          fetch_zstd_path(Recordings.cast_cache_bucket(true), popcast.id, path)

        {false, :gzip} ->
          fetch_gzip_path(:pop_gz, popcast.id, path)

        {false, :identity} ->
          {:ok, path}
      end
    end
  end

  defp get_svg_path(popcast, params, cache_key, encoding) do
    variant = if params["f"] == "t", do: :thumbnail, else: :full

    result =
      FileCache.fetch_path(:svg, {popcast.id, variant, cache_key}, fn tmp_dir ->
        path = Path.join(tmp_dir, "#{popcast.id}.svg")
        svg = RecordingSVG.render_to_iodata(variant, popcast)
        File.write!(path, svg)

        path
      end)

    with {:ok, path} <- result do
      key = {popcast.id, variant, cache_key}

      case encoding do
        :identity -> {:ok, path}
        :gzip -> fetch_gzip_path(:svg_gz, key, path)
        :zstd -> fetch_zstd_path(:svg_zst, key, path)
      end
    end
  end

  defp get_txt_path(popcast, encoding) do
    result =
      FileCache.fetch_path(:txt, popcast.id, fn tmp_dir ->
        path = Path.join(tmp_dir, "#{popcast.id}.txt")
        File.write!(path, Recordings.text(popcast))

        path
      end)

    with {:ok, path} <- result do
      case encoding do
        :identity -> {:ok, path}
        :gzip -> fetch_gzip_path(:txt_gz, popcast.id, path)
        :zstd -> fetch_zstd_path(:txt_zst, popcast.id, path)
      end
    end
  end

  defp fetch_gzip_path(bucket, key, source_path, source_encoding \\ :identity) do
    FileCache.fetch_path(
      bucket,
      key,
      fn tmp_dir ->
        gz_path = Path.join(tmp_dir, Path.basename(source_path)) <> ".gz"

        source_path
        |> stream_path!(source_encoding)
        |> Enum.into(Gzip.stream!(gz_path, @encoding_chunk_size))

        gz_path
      end,
      15_000
    )
  end

  defp fetch_zstd_path(bucket, key, source_path) do
    FileCache.fetch_path(
      bucket,
      key,
      fn tmp_dir ->
        zst_path = Path.join(tmp_dir, Path.basename(source_path)) <> ".zst"

        source_path
        |> File.stream!([], @encoding_chunk_size)
        |> Enum.into(Zstd.stream!(zst_path, @encoding_chunk_size))

        zst_path
      end,
      15_000
    )
  end

  defp fetch_plain_path(bucket, key, source_path, source_encoding) do
    FileCache.fetch_path(
      bucket,
      key,
      fn tmp_dir ->
        path = Path.join(tmp_dir, Path.rootname(Path.basename(source_path), ".zst"))

        source_path
        |> stream_path!(source_encoding)
        |> Enum.into(File.stream!(path, [:write, :binary], @encoding_chunk_size))

        path
      end,
      15_000
    )
  end

  defp get_png_path(popcast, cache_key) do
    FileCache.fetch_path(
      :png,
      {popcast.id, cache_key},
      &PngGenerator.generate(popcast, &1),
      @png_cache_timeout
    )
  end

  defp put_content_disposition(conn, nil), do: conn

  defp put_content_disposition(conn, filename) do
    put_resp_header(conn, "content-disposition", "attachment; filename=#{filename}")
  end

  defp maybe_put_content_encoding(conn, :zstd) do
    put_resp_header(conn, "content-encoding", "zstd")
  end

  defp maybe_put_content_encoding(conn, :gzip) do
    put_resp_header(conn, "content-encoding", "gzip")
  end

  defp maybe_put_content_encoding(conn, :identity), do: conn

  defp stream_path!(path, :identity), do: File.stream!(path, [], @encoding_chunk_size)
  defp stream_path!(path, :zstd), do: Zstd.stream!(path, @encoding_chunk_size)

  defp preferred_response_encoding(conn) do
    encodings = accepted_encodings(conn)

    cond do
      accepted?(encodings, "zstd") -> :zstd
      accepted?(encodings, "gzip") -> :gzip
      true -> :identity
    end
  end

  defp accepted_encodings(conn) do
    conn
    |> get_req_header("accept-encoding")
    |> Enum.flat_map(&String.split(&1, ","))
    |> Enum.reduce(%{}, fn encoding, acc ->
      {name, q} = parse_accept_encoding(encoding)
      Map.update(acc, name, q, &max(&1, q))
    end)
  end

  defp accepted?(encodings, encoding), do: Map.get(encodings, encoding, 0.0) > 0.0

  defp parse_accept_encoding(value) do
    [name | params] =
      value
      |> String.split(";")
      |> Enum.map(&String.trim/1)

    name = String.downcase(name)
    q = Enum.reduce(params, 1.0, &parse_accept_encoding_param/2)

    {name, q}
  end

  defp parse_accept_encoding_param(param, q) do
    case String.split(param, "=", parts: 2) do
      [name, value] ->
        if String.downcase(String.trim(name)) == "q" do
          parse_q(value)
        else
          q
        end

      _ ->
        q
    end
  end

  defp parse_q(value) do
    case Float.parse(String.trim(value)) do
      {q, ""} when q >= 0.0 and q <= 1.0 -> q
      _ -> 0.0
    end
  end

  defp fetch_other_popcasts(popcast, current_user) do
    %RecordingQuery{
      scope: {:listing_for, current_user},
      filters: [{:user, popcast.user_id}, {:id, {:not_eq, popcast.id}}],
      sort: :random
    }
    |> list_popcasts(4)
  end

  defp list_popcasts(query, limit) do
    items = Recordings.list(query, limit + 1)

    %{
      items: Enum.take(items, limit),
      has_more: length(items) > limit
    }
  end

  def edit(conn, _params) do
    changeset = Recordings.change_popcast(conn.assigns.popcast)
    render_edit_form(conn, changeset)
  end

  def update(conn, %{"popcast" => popcast_params}) do
    popcast = conn.assigns.popcast

    case Recordings.update_popcast(popcast, popcast_params) do
      {:ok, popcast} ->
        conn
        |> put_flash(:info, "Recording updated.")
        |> redirect(to: ~p"/a/#{popcast}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render_edit_form(conn, changeset)
    end
  end

  defp render_edit_form(conn, changeset) do
    render(conn, "edit.html", changeset: changeset, instance_url: PopcornWeb.Endpoint.url())
  end

  def delete(conn, _params) do
    popcast = conn.assigns.popcast

    case Recordings.delete_popcast(popcast) do
      {:ok, _popcast} ->
        conn
        |> put_flash(:info, "Recording deleted.")
        |> redirect(to: ~p"/~#{conn.assigns.current_user}")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Couldn't remove this recording.")
        |> redirect(to: ~p"/a/#{popcast}")
    end
  end

  def iframe(conn, params) do
    conn =
      conn
      |> put_layout("iframe.html")
      |> delete_resp_header("x-frame-options")

    if conn.assigns.popcast.archived_at do
      conn
      |> put_status(410)
      |> render("deleted.html", ttl: Popcorn.unclaimed_recording_ttl())
    else
      render(conn, "iframe.html", player_opts: player_opts(params))
    end
  end

  defp attachment_filename(%Popcast{version: version, id: id}, %{"dl" => _}) do
    case version do
      0 -> "#{id}.json"
      1 -> "#{id}.json"
      2 -> "#{id}.pop"
      3 -> "#{id}.pop"
    end
  end

  defp attachment_filename(_popcast, _params) do
    nil
  end

  defp load_and_authorize_popcast(conn, _) do
    id = String.trim(conn.params["id"])

    case Recordings.lookup_popcast(id, load_snapshot: true) do
      nil ->
        conn
        |> FallbackController.call({:error, :not_found})
        |> halt()

      popcast ->
        user = conn.assigns[:current_user]
        action = Phoenix.Controller.action_name(conn)

        if Authorization.can?(user, action, popcast) do
          assign(conn, :popcast, popcast)
        else
          status = if Recordings.secret_token?(id), do: :forbidden, else: :not_found

          conn
          |> FallbackController.call({:error, status})
          |> halt()
        end
    end
  end

  defp redirect_to_canonical_path(conn, _) do
    id = String.trim(conn.params["id"])
    popcast = conn.assigns.popcast

    if get_format(conn) == "html" && id != Phoenix.Param.to_param(popcast) do
      conn
      |> redirect(to: ~p"/a/#{popcast}")
      |> halt()
    else
      conn
    end
  end

  @actions [:edit, :delete]

  defp popcast_actions(popcast, user) do
    Enum.filter(@actions, &Authorization.can?(user, &1, popcast))
  end

  defp player_opts(params) do
    params
    |> Ext.Map.rename(%{"t" => "startAt", "i" => "idleTimeLimit"})
    |> PlayerOpts.parse(:recording)
  end

  defp build_view_count_url(conn, popcast) do
    case conn.req_cookies["a#{popcast.id}"] do
      nil ->
        token = Recordings.generate_view_count_token(popcast.id)
        ~p"/a/#{popcast}/views?token=#{token}"

      _ ->
        nil
    end
  end
end
