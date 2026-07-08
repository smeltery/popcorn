defmodule Popcorn.Recordings do
  require Logger
  import Ecto, only: [build_assoc: 2]
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Popcorn.Popcast.Reader
  alias Popcorn.Popcast.{V1, V2, V3}
  alias Popcorn.{FileCache, FileStore, Fonts, Fts, HttpUtil, Repo, Themes, Vt, Zstd}
  alias Popcorn.Workers.{MigrateRecordingFiles, UpdateFtsContent, UpdateSnapshot}

  alias Popcorn.Recordings.{
    Listing,
    Popcast,
    Popularity,
    Markers,
    Paths,
    Query,
    Text
  }

  alias Ecto.Changeset

  @secret_token_length 16
  @legacy_secret_token_length 25
  @secret_token_lengths [@secret_token_length, @legacy_secret_token_length]
  @secret_token_re ~r/^[[:alnum:]]+$/

  def get_popcast(id, opts \\ []) do
    Popcast
    |> maybe_load_snapshot(opts)
    |> Repo.get(id)
    |> Repo.preload([:user, :stats])
  end

  def get_popcast!(id, opts \\ []) do
    Popcast
    |> maybe_load_snapshot(opts)
    |> Repo.get!(id)
    |> Repo.preload([:user, :stats])
  end

  def get_public_popcast(id, opts \\ []) do
    Popcast
    |> maybe_load_snapshot(opts)
    |> Repo.get_by(id: id, visibility: :public)
    |> Repo.preload([:user, :stats])
  end

  def fetch_popcast(id), do: OK.required(get_popcast(id), :not_found)

  def find_popcast_by_secret_token(token, opts \\ []) do
    from(a in Popcast, where: a.secret_token == ^token)
    |> maybe_load_snapshot(opts)
    |> Repo.one()
    |> Repo.preload([:user, :stats])
  end

  def lookup_popcast(id, opts \\ []) when is_binary(id) do
    cond do
      String.match?(id, ~r/^\d+$/) ->
        if Keyword.get(opts, :allow_non_public_id, false) do
          get_popcast(id, opts)
        else
          get_public_popcast(id, opts)
        end

      secret_token?(id) ->
        find_popcast_by_secret_token(id, opts)

      true ->
        nil
    end
  end

  def fetch_cast_path(popcast) do
    bucket = cast_cache_bucket(popcast.compressed)

    case FileStore.uri(popcast.path) do
      "file://" <> path ->
        {:ok, path}

      "http" <> _rest = url ->
        FileCache.fetch_path(
          bucket,
          popcast.id,
          fn tmp_dir ->
            path = Path.join(tmp_dir, to_string(popcast.id))

            :ok =
              HttpUtil.download_to(url, path,
                timeout: 30_000,
                decompress: false
              )

            path
          end,
          40_000
        )
    end
  end

  def cast_cache_bucket(true), do: :pop_zst
  def cast_cache_bucket(false), do: :pop

  def get_cast_path!(popcast) do
    case fetch_cast_path(popcast) do
      {:ok, path} ->
        path

      {:error, error} ->
        raise error
    end
  end

  defp maybe_load_snapshot(query, opts) do
    if Keyword.get(opts, :load_snapshot, false) do
      select(query, [popcast], %{popcast | snapshot: popcast.snapshot})
    else
      query
    end
  end

  def secret_token?(token) when is_binary(token) do
    String.match?(token, @secret_token_re) and byte_size(token) in @secret_token_lengths
  end

  def query(%Query{} = spec), do: Listing.query(spec)

  def paginate(query, page, page_size, opts \\ [])

  def paginate(%Query{} = spec, page, page_size, opts) do
    spec
    |> query()
    |> paginate(page, page_size, opts)
  end

  def paginate(%Ecto.Query{} = query, page, page_size, opts) do
    paginate_opts =
      [page: page, page_size: page_size] ++ maybe_total_entries_opt(query, page_size, opts)

    query
    |> maybe_with_total_views(Keyword.get(opts, :with_total_views, false))
    |> maybe_preload(Keyword.get(opts, :preload, [:user]))
    |> Repo.paginate(paginate_opts)
  end

  def search_paginate(query, page, page_size, opts \\ [])

  def search_paginate(%Query{} = spec, page, page_size, opts) do
    spec
    |> query()
    |> search_paginate(page, page_size, opts)
  end

  def search_paginate(%Ecto.Query{} = query, page, page_size, opts) do
    Repo.with_work_mem(Listing.search_work_mem(), fn ->
      paginate(query, page, page_size, opts)
    end)
  end

  defp maybe_total_entries_opt(query, page_size, opts) do
    case opts[:max_pages] do
      nil ->
        []

      max_pages ->
        max_entries = page_size * max_pages
        limit = max_entries + 1

        limited_count =
          query
          |> exclude(:preload)
          |> exclude(:order_by)
          |> exclude(:select)
          |> select([popcast], popcast.id)
          |> limit(^limit)
          |> subquery()
          |> select([entry], count(entry.id))
          |> Repo.one()

        [options: [total_entries: min(limited_count || 0, max_entries)]]
    end
  end

  defp maybe_preload(query, []), do: query
  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preloads), do: preload(query, ^preloads)

  def list(q, limit, opts \\ [])

  def list(%Query{} = spec, limit, opts) do
    spec
    |> query()
    |> list(limit, opts)
  end

  def list(q, limit, opts) do
    q
    |> maybe_with_total_views(Keyword.get(opts, :with_total_views, false))
    |> limit(^limit)
    |> maybe_preload(Keyword.get(opts, :preload, [:user]))
    |> Repo.all()
  end

  defp maybe_with_total_views(q, true), do: Listing.with_total_views(q)
  defp maybe_with_total_views(q, false), do: q

  def stream(%Query{} = spec) do
    spec
    |> query()
    |> stream()
  end

  def stream(%Ecto.Query{} = query) do
    query
    |> maybe_preload([:user])
    |> Repo.pages(100)
    |> Stream.flat_map(& &1)
  end

  def uncompressed_popcast_ids_stream do
    from(a in Popcast,
      where: a.compressed == false,
      select: %{id: a.id}
    )
    |> Repo.pages(1000)
    |> Stream.flat_map(& &1)
    |> Stream.map(& &1.id)
  end

  def count(%Query{} = spec), do: spec |> query() |> count()
  def count(q), do: Repo.count(q)

  @doc """
  Total number of recordings owned by the user (including archived ones).
  """
  def count_user_popcasts(user), do: Repo.count(Ecto.assoc(user, :popcasts))

  @doc """
  Returns `{compressed_total, uncompressed_total}` bytes summed across the
  user's recordings. Either side is `nil` when no recording has that size set.
  """
  def byte_totals(user_id) do
    Repo.one(
      from(a in Popcast,
        where: a.user_id == ^user_id,
        select: {sum(a.compressed_size), sum(a.uncompressed_size)}
      )
    )
  end

  @doc "List of `{Date, count}` of new recordings per day over the last `days` days, oldest first."
  def recordings_by_day(days) when is_integer(days) and days > 0 do
    today = Date.utc_today()
    start_date = Date.add(today, -(days - 1))
    cutoff = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")

    rows =
      from(a in Popcast,
        where: a.inserted_at >= ^cutoff,
        group_by: fragment("date_trunc('day', ?)::date", a.inserted_at),
        select: {fragment("date_trunc('day', ?)::date", a.inserted_at), count()}
      )
      |> Repo.all()
      |> Map.new()

    start_date
    |> Date.range(today)
    |> Enum.map(fn d -> {d, Map.get(rows, d, 0)} end)
  end

  def count_by(%Query{} = spec, field), do: spec |> query() |> count_by(field)

  def count_by(q, :stream) do
    count_by(q, :stream_id)
  end

  def count_by(q, field) do
    from(a in q, group_by: field(a, ^field), select: {field(a, ^field), count(a.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  def create_popcast(user, local_path, attrs \\ %{}, params \\ %{})
      when is_binary(local_path) do
    with {:ok, metadata} <- extract_metadata(local_path),
         :ok <- validate_not_empty(metadata),
         metadata = Map.put(metadata, :filename, normalize_filename(params)),
         changeset = build_popcast(user, attrs, metadata, params),
         :ok <- validate_popcast(changeset),
         {compressed_path, changeset} = compress_file(local_path, changeset),
         {store_path, changeset} = assign_store_path(changeset),
         :ok <- save_file(compressed_path, store_path),
         {:ok, popcast} <- insert_popcast_or_delete_file(changeset, store_path),
         :ok <- schedule_bg_jobs(popcast) do
      {:ok, popcast}
    end
  end

  defp build_popcast(user, attrs, metadata, params) do
    defaults = %{
      visibility: user.default_recording_visibility,
      secret_token: generate_secret_token(),
      term_bold_is_bright: user.term_bold_is_bright,
      term_adaptive_palette: user.term_adaptive_palette,
      term_theme_name: term_theme_name(user, metadata)
    }

    {version, metadata} = Map.pop!(metadata, :version)
    {filename, metadata} = Map.pop!(metadata, :filename)
    {duration, metadata} = Map.pop!(metadata, :duration)
    metadata = Map.delete(metadata, :event_count)

    attrs =
      Map.merge(attrs, %{
        version: version,
        filename: filename,
        duration: duration
      })

    user
    |> build_assoc(:popcasts)
    |> change(defaults)
    |> change(attrs)
    |> foreign_key_constraint(:stream_id)
    |> apply_metadata(metadata)
    |> change_popcast(params)
  end

  defp validate_popcast(%Changeset{valid?: true}), do: :ok
  defp validate_popcast(%Changeset{valid?: false} = changeset), do: {:error, changeset}

  defp compress_file(input_path, changeset) do
    output_path = Zstd.compress_file(input_path, compression_level: 9)

    changeset =
      change(changeset, %{
        uncompressed_size: file_size(input_path),
        compressed_size: file_size(output_path),
        compressed: true
      })

    {output_path, changeset}
  end

  defp assign_store_path(changeset) do
    # Paths.path/1 needs id and inserted_at so we have to prepare them here
    changeset =
      if Changeset.get_field(changeset, :id) != nil do
        changeset
      else
        change(changeset,
          id: get_next_popcast_id(),
          inserted_at: DateTime.truncate(DateTime.utc_now(), :second)
        )
      end

    popcast =
      changeset
      |> Changeset.apply_changes()
      |> Repo.preload(:user, force: true)

    path = Paths.path(popcast)
    changeset = change(changeset, path: path)

    {path, changeset}
  end

  defp save_file(local_path, store_path) do
    FileStore.put_file(store_path, local_path, "application/x-popcast")
  end

  defp get_next_popcast_id do
    [[id]] = Repo.query!("SELECT nextval('popcasts_id_seq')").rows

    id
  end

  defp insert_popcast_or_delete_file(changeset, store_path) do
    try do
      case Repo.insert(changeset) do
        {:ok, popcast} ->
          {:ok, popcast}

        {:error, changeset} ->
          maybe_delete_file(store_path)
          {:error, changeset}
      end
    rescue
      error ->
        maybe_delete_file(store_path)
        reraise error, __STACKTRACE__
    end
  end

  defp schedule_bg_jobs(popcast) do
    if popcast.snapshot == nil do
      schedule_snapshot_update(popcast.id)
    end

    schedule_fts_content_update(popcast.id)

    :ok
  end

  defp term_theme_name(user, metadata) do
    if metadata[:term_theme_palette] && user.term_theme_prefer_original do
      "original"
    end
  end

  defp file_size(path) do
    File.stat!(path).size
  end

  defp extract_metadata(path) when is_binary(path) do
    if Reader.compressed?(path) do
      {:error, :invalid_format}
    else
      case V2.fetch_metadata(path) do
        {:ok, metadata} -> {:ok, metadata}
        {:error, {:invalid_version, 3}} -> V3.fetch_metadata(path)
        {:error, {:invalid_version, _} = reason} -> {:error, reason}
        {:error, :invalid_format} -> V1.fetch_metadata(path)
      end
    end
  end

  defp validate_not_empty(%{event_count: count}) when count > 0, do: :ok
  defp validate_not_empty(%{event_count: 0}), do: {:error, :empty_recording}

  @max_filename_len 255

  defp normalize_filename(params) do
    case params["filename"] || params[:filename] do
      filename when is_binary(filename) ->
        filename
        |> Path.basename()
        |> String.slice(0, @max_filename_len)

      _ ->
        "popcast.pop"
    end
  end

  @allowed_metadata [
    :term_cols,
    :term_rows,
    :term_type,
    :term_version,
    :term_theme_fg,
    :term_theme_bg,
    :term_theme_palette,
    :command,
    :shell,
    :recorded_at,
    :env,
    :idle_time_limit,
    :title
  ]

  @max_title_len 128
  @max_description_len 4096
  @max_term_type_len 64
  @max_term_version_len 255
  @max_shell_len 255
  @max_command_len 255
  @max_audio_url_len 255
  @max_term_cols 720
  @max_term_rows 200
  @hex_color_re ~r/^#[0-9a-f]{6}$/
  @hex_palette_re ~r/^(#[0-9a-f]{6}:){7}((#[0-9a-f]{6}:){8})?#[0-9a-f]{6}$/

  defp apply_metadata(changeset, metadata) do
    changeset
    |> cast(metadata, @allowed_metadata)
    |> validate_required([:term_cols, :term_rows])
    |> validate_number(:term_cols, greater_than: 0, less_than_or_equal_to: @max_term_cols)
    |> validate_number(:term_rows, greater_than: 0, less_than_or_equal_to: @max_term_rows)
    |> validate_format(:term_theme_fg, @hex_color_re)
    |> validate_format(:term_theme_bg, @hex_color_re)
    |> validate_format(:term_theme_palette, @hex_palette_re)
    |> validate_change(:env, &validate_env/2)
    |> truncate(:term_type, @max_term_type_len)
    |> truncate(:term_version, @max_term_version_len)
    |> truncate(:command, @max_command_len)
    |> truncate(:shell, @max_shell_len)
    |> truncate(:title, @max_title_len)
  end

  defp validate_env(:env, env) do
    errors = []

    errors =
      if Enum.all?(Map.keys(env), &String.match?(&1, ~r/^[A-Z0-9_]+$/)) do
        errors
      else
        [{:env, "must include valid env var names"} | errors]
      end

    errors =
      if Enum.all?(Map.values(env), &is_binary/1) do
        errors
      else
        [{:env, "must include only string values"} | errors]
      end

    errors
  end

  defp truncate(changeset, field, max_len) do
    update_change(changeset, field, fn value ->
      if value, do: String.slice(value, 0, max_len)
    end)
  end

  defp schedule_snapshot_update(popcast_id) do
    %{popcast_id: popcast_id}
    |> UpdateSnapshot.new()
    |> Oban.insert!()
  end

  defp schedule_fts_content_update(popcast_id) do
    %{popcast_id: popcast_id}
    |> UpdateFtsContent.new()
    |> Oban.insert!()
  end

  def change_popcast(popcast, attrs \\ %{}) do
    popcast
    |> cast(attrs, [
      :visibility,
      :title,
      :description,
      :term_cols_override,
      :term_rows_override,
      :term_theme_name,
      :term_bold_is_bright,
      :term_adaptive_palette,
      :term_line_height,
      :term_font_family,
      :term_cursor_mode,
      :keystroke_overlay,
      :idle_time_limit,
      :speed,
      :snapshot_at,
      :markers,
      :audio_url
    ])
    |> validate_length(:title, max: @max_title_len)
    |> validate_length(:description, max: @max_description_len)
    |> validate_length(:audio_url, max: @max_audio_url_len)
    |> validate_format(:audio_url, ~r|^https?://|)
    |> validate_number(:term_cols_override,
      greater_than: 0,
      less_than_or_equal_to: @max_term_cols
    )
    |> validate_number(:term_rows_override,
      greater_than: 0,
      less_than_or_equal_to: @max_term_rows
    )
    |> validate_number(:idle_time_limit, greater_than: 0.0)
    |> validate_inclusion(:term_theme_name, Themes.terminal_themes() ++ ["original"])
    |> validate_number(:term_line_height,
      greater_than_or_equal_to: 1.0,
      less_than_or_equal_to: 2.0
    )
    |> validate_inclusion(:term_font_family, Fonts.terminal_font_families())
    |> validate_inclusion(:term_cursor_mode, ~w[blinking steady hidden])
    |> validate_number(:snapshot_at, greater_than: 0)
    |> validate_change(:markers, &Markers.validate/2)
  end

  def update_popcast(popcast, attrs \\ %{}) do
    changeset = change_popcast(popcast, attrs)

    with {:ok, popcast} <- Repo.update(changeset) do
      if stale_snapshot?(changeset) do
        update_snapshot(popcast)
      else
        {:ok, popcast}
      end
    end
  end

  defp stale_snapshot?(changeset) do
    changed?(changeset, :snapshot_at) ||
      changed?(changeset, :term_cols_override) ||
      changed?(changeset, :term_rows_override)
  end

  def set_featured(popcast, featured \\ true) do
    popcast
    |> Changeset.change(%{featured: featured})
    |> Repo.update()
  end

  def archive(popcast) do
    popcast
    |> Changeset.change(%{archived_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Reverses an archive: clears `archived_at` and marks the recording not
  archivable, so the auto-archiver won't immediately archive it again.
  """
  def unarchive(popcast) do
    popcast
    |> Changeset.change(%{archived_at: nil, archivable: false})
    |> Repo.update()
  end

  def delete_popcast(popcast) do
    with {:ok, popcast} <- Repo.delete(popcast) do
      case FileStore.delete_file(popcast.path) do
        :ok -> {:ok, popcast}
        {:error, :enoent} -> {:ok, popcast}
        otherwise -> otherwise
      end
    end
  end

  def compress_popcast(%Popcast{compressed: true} = popcast), do: {:ok, popcast}

  def compress_popcast(%Popcast{} = popcast) do
    popcast = Repo.preload(popcast, :user)
    old_store_path = popcast.path
    source_path = get_cast_path!(popcast)
    {zst_path, changeset} = compress_file(source_path, popcast)
    {new_store_path, changeset} = assign_store_path(changeset)
    :ok = save_file(zst_path, new_store_path)
    _ = File.rm(zst_path)

    try do
      popcast = Repo.update!(changeset)
      maybe_delete_file(old_store_path)

      {:ok, popcast}
    rescue
      error ->
        maybe_delete_file(new_store_path)
        reraise error, __STACKTRACE__
    end
  end

  def delete_popcasts(%{popcasts: _} = owner) do
    delete_popcasts(Ecto.assoc(owner, :popcasts))
  end

  def delete_popcasts(%Ecto.Query{} = query) do
    popcasts = Repo.all(query)

    Enum.each(popcasts, fn a ->
      {:ok, _} = delete_popcast(a)
    end)

    length(popcasts)
  end

  def update_snapshot(%Popcast{} = popcast) do
    cols = popcast.term_cols_override || popcast.term_cols
    rows = popcast.term_rows_override || popcast.term_rows
    secs = popcast.snapshot_at || popcast.duration / 2

    snapshot =
      popcast
      |> event_stream()
      |> output()
      |> generate_snapshot(cols, rows, secs)

    popcast
    |> Changeset.cast(%{snapshot: snapshot}, [:snapshot])
    |> Repo.update()
  end

  def generate_snapshot(output_stream, cols, rows, secs) do
    {:ok, vt} = Vt.new(cols, rows, 0)

    output_stream
    |> Stream.take_while(&frame_before_or_at?(&1, secs))
    |> Enum.each(fn {_, text} -> Vt.feed(vt, text) end)

    Vt.dump_screen(vt)
  end

  def update_fts_content(%Popcast{} = popcast) do
    cols = popcast.term_cols_override || popcast.term_cols
    rows = popcast.term_rows_override || popcast.term_rows

    content =
      popcast
      |> event_stream()
      |> generate_fts_content(cols, rows)

    set_content_tsv(popcast.id, content)
  end

  defp set_content_tsv(id, content, attempt \\ 1) do
    try do
      Repo.update_all(
        from(f in "popcast_fts",
          where: f.popcast_id == ^id,
          update: [set: [content_tsv: fragment("to_tsvector('simple', ?)", ^content)]]
        ),
        []
      )

      :ok
    rescue
      e in Postgrex.Error ->
        if e.postgres.code == :program_limit_exceeded do
          if attempt < 10 do
            content = String.slice(content, 0, div(String.length(content) * 9, 10))
            set_content_tsv(id, content, attempt + 1)
          else
            {:error, :too_long}
          end
        else
          reraise e, __STACKTRACE__
        end
    end
  end

  def generate_fts_content(events, cols, rows) do
    {:ok, fts} = Fts.new(cols, rows)

    events
    |> Stream.each(fn {_, code, data} ->
      case code do
        "o" ->
          Fts.feed(fts, data)

        "r" ->
          {cols, rows} = data
          Fts.resize(fts, cols, rows)

        _ ->
          :ok
      end
    end)
    |> Stream.run()

    Fts.dump(fts)
  end

  def event_stream(%Popcast{} = popcast) do
    path = get_cast_path!(popcast)
    opts = [compressed: popcast.compressed]

    case popcast.version do
      1 -> V1.event_stream(path, opts)
      2 -> V2.event_stream(path, opts)
      3 -> V3.event_stream(path, opts)
    end
  end

  def output(stream) do
    stream
    |> Stream.filter(fn {_, code, _} -> code == "o" end)
    |> Stream.map(fn {time, _, data} -> {time, data} end)
  end

  def title(popcast) do
    cond do
      popcast.title not in [nil, ""] ->
        popcast.title

      popcast.command not in [nil, ""] && popcast.command != popcast.shell ->
        popcast.command

      true ->
        "untitled"
    end
  end

  defdelegate text(popcast), to: Text

  defp frame_before_or_at?({time, _}, secs) do
    time <= secs
  end

  defp maybe_delete_file(path) do
    case FileStore.delete_file(path) do
      :ok ->
        :ok

      {:error, :enoent} ->
        :ok

      {:error, reason} ->
        Logger.warning("failed to delete file #{path}: #{inspect(reason)}")
        :ok
    end
  end

  def recompute_popularity_scores(scope \\ :all), do: Popularity.recompute_scores(scope)

  def register_view(popcast, date \\ Date.utc_today()),
    do: Popularity.register_view(popcast, date)

  def migratable(stream), do: Stream.filter(stream, &stale_path?/1)

  defp stale_path?(popcast) do
    popcast.path != Paths.path(popcast)
  end

  def migrate_files(user) do
    %{user_id: user.id}
    |> MigrateRecordingFiles.new()
    |> Oban.insert!()

    :ok
  end

  def migrate_file(id) when is_integer(id) do
    id
    |> get_popcast()
    |> migrate_file()
  end

  def migrate_file(popcast) do
    cur_path = popcast.path
    new_path = Paths.path(popcast)

    if cur_path != new_path do
      changeset = change(popcast, path: new_path)

      {:ok, popcast} =
        Repo.transact(fn ->
          popcast = Repo.update!(changeset)
          :ok = FileStore.move_file(cur_path, new_path)

          {:ok, popcast}
        end)

      popcast
    else
      popcast
    end
  end

  def hide_unclaimed_popcasts(tmp_users_query, t) do
    query =
      from a in Popcast,
        join: u in ^tmp_users_query,
        on: a.user_id == u.id,
        where: a.archivable and is_nil(a.archived_at) and a.inserted_at < ^t

    {count, _} = Repo.update_all(query, set: [archived_at: Timex.now()])

    count
  end

  def delete_unclaimed_popcasts(tmp_users_query, t) do
    query =
      from a in Popcast,
        join: u in ^tmp_users_query,
        on: a.user_id == u.id,
        where: a.archivable and a.inserted_at < ^t

    delete_popcasts(query)
  end

  def reassign_popcasts(src_user_id, dst_user_id) do
    q = from(a in Popcast, where: a.user_id == ^src_user_id)
    Repo.update_all(q, set: [user_id: dst_user_id, updated_at: Timex.now()])
  end

  defp generate_secret_token, do: Crypto.random_token(@secret_token_length)

  # View count token - valid for 24 hours
  @view_count_token_max_age 3600 * 24

  def generate_view_count_token(popcast_id) do
    Phoenix.Token.sign(PopcornWeb.Endpoint, "view-count", popcast_id)
  end

  def verify_view_count_token(token) do
    Phoenix.Token.verify(PopcornWeb.Endpoint, "view-count", token,
      max_age: @view_count_token_max_age
    )
  end
end
