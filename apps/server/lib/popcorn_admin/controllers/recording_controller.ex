defmodule PopcornAdmin.RecordingController do
  use PopcornAdmin, :controller

  alias Popcorn.{Recordings, Zstd}
  alias PopcornAdmin.{IndexQuery, RecordingHTML}

  @page_size 50
  @cast_chunk_size 64 * 1024

  def index(conn, params) do
    index = IndexQuery.build(:recordings, params)

    page =
      if index.valid? do
        Recordings.paginate(index.query, params["page"], @page_size,
          preload: [:user],
          with_total_views: true
        )
      else
        IndexQuery.empty_page(params["page"], @page_size)
      end

    render(conn, :index,
      page_title: "Recordings",
      recordings: page.entries,
      page: page,
      index: index,
      filter_params: index.query_params
    )
  end

  def show(conn, %{"id" => id}) do
    popcast = Recordings.get_popcast!(id, load_snapshot: true)

    render(conn, :show,
      page_title: popcast.title || "Recording ##{popcast.id}",
      popcast: popcast,
      player_src: RecordingHTML.player_src(popcast),
      player_opts: RecordingHTML.player_opts(popcast)
    )
  end

  @doc """
  Serves the cast file same-origin, sidestepping the public endpoint's
  visibility checks so the player reaches private recordings.
  """
  def cast_file(conn, %{"id" => id}) do
    popcast = Recordings.get_popcast!(id)
    {:ok, path} = Recordings.fetch_cast_path(popcast)

    conn =
      conn
      |> put_resp_header("content-type", "application/x-popcast")
      |> put_resp_header("cache-control", "no-store")

    # remote/S3 files are cached without a .zst suffix, hence the schema flag
    cond do
      not popcast.compressed ->
        send_file(conn, 200, path)

      accepts_zstd?(conn) ->
        conn
        |> put_resp_header("content-encoding", "zstd")
        |> send_file(200, path)

      true ->
        conn = send_chunked(conn, 200)

        path
        |> Zstd.stream!(@cast_chunk_size)
        |> Enum.reduce_while(conn, fn data, conn ->
          case chunk(conn, data) do
            {:ok, conn} -> {:cont, conn}
            {:error, _} -> {:halt, conn}
          end
        end)
    end
  end

  defp accepts_zstd?(conn) do
    conn
    |> get_req_header("accept-encoding")
    |> Enum.any?(&String.contains?(&1, "zstd"))
  end

  def edit(conn, %{"id" => id}) do
    popcast = Recordings.get_popcast!(id)

    render(conn, :edit,
      page_title: "Edit recording ##{popcast.id}",
      popcast: popcast,
      changeset: Recordings.change_popcast(popcast)
    )
  end

  def update(conn, %{"id" => id, "popcast" => attrs}) do
    popcast = Recordings.get_popcast!(id)

    case Recordings.update_popcast(popcast, attrs) do
      {:ok, popcast} ->
        conn
        |> put_flash(:info, "Recording updated.")
        |> redirect(to: ~p"/admin/recordings/#{popcast.id}")

      {:error, changeset} ->
        render(conn, :edit,
          page_title: "Edit recording ##{popcast.id}",
          popcast: popcast,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    popcast = Recordings.get_popcast!(id)
    {:ok, _} = Recordings.delete_popcast(popcast)

    conn
    |> put_flash(:info, "Recording ##{popcast.id} deleted.")
    |> redirect(to: ~p"/admin/recordings")
  end

  def set_visibility(conn, %{"id" => id, "visibility" => vis}) do
    popcast = Recordings.get_popcast!(id)

    case Recordings.update_popcast(popcast, %{visibility: vis}) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Visibility set to #{vis}.")
        |> redirect(to: ~p"/admin/recordings/#{popcast.id}")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not update visibility.")
        |> redirect(to: ~p"/admin/recordings/#{popcast.id}")
    end
  end

  def set_featured(conn, %{"id" => id, "featured" => featured}) do
    popcast = Recordings.get_popcast!(id)
    val = featured == "true"

    case Recordings.set_featured(popcast, val) do
      {:ok, _} ->
        conn
        |> put_flash(:info, if(val, do: "Featured.", else: "Unfeatured."))
        |> redirect(to: ~p"/admin/recordings/#{popcast.id}")

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not update featured flag.")
        |> redirect(to: ~p"/admin/recordings/#{popcast.id}")
    end
  end

  def unarchive(conn, %{"id" => id}) do
    popcast = Recordings.get_popcast!(id)

    case Recordings.unarchive(popcast) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Unarchived.")
        |> redirect(to: ~p"/admin/recordings/#{popcast.id}")

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not unarchive.")
        |> redirect(to: ~p"/admin/recordings/#{popcast.id}")
    end
  end

  def archive(conn, %{"id" => id}) do
    popcast = Recordings.get_popcast!(id)

    case Recordings.archive(popcast) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Archived.")
        |> redirect(to: ~p"/admin/recordings/#{popcast.id}")

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not archive.")
        |> redirect(to: ~p"/admin/recordings/#{popcast.id}")
    end
  end
end
