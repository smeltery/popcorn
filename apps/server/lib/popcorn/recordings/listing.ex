defmodule Popcorn.Recordings.Listing do
  import Ecto.Query, warn: false

  alias Popcorn.Recordings.{Popcast, Query}

  @search_work_mem "32MB"

  def query(%Query{} = spec) do
    Popcast
    |> apply_scope(spec.scope)
    |> apply_archived(spec.archived)
    |> apply_filters(spec.filters)
    |> sort(spec.sort, spec.filters)
  end

  def search_work_mem do
    Application.get_env(:popcorn, :search_work_mem, @search_work_mem)
  end

  def with_total_views(q) do
    q
    |> ensure_stats_left_join()
    |> select_merge([stats_left: s], %{total_views: coalesce(s.total_views, 0)})
  end

  defp apply_scope(query, :system), do: query
  defp apply_scope(query, :admin), do: query

  defp apply_scope(query, :public_listing),
    do: where(query, [a], a.visibility == :public)

  defp apply_scope(query, {:listing_for, nil}), do: apply_scope(query, :public_listing)

  defp apply_scope(query, {:listing_for, %{id: user_id}}),
    do: where(query, [a], a.visibility == :public or a.user_id == ^user_id)

  defp apply_archived(query, :exclude), do: where(query, [a], is_nil(a.archived_at))
  defp apply_archived(query, :include), do: query
  defp apply_archived(query, :only), do: where(query, [a], not is_nil(a.archived_at))

  defp apply_filters(q, filters) when is_list(filters) do
    filters
    |> Enum.uniq()
    |> Enum.reduce(q, &apply_filter/2)
  end

  defp apply_filters(q, filter), do: apply_filters(q, List.wrap(filter))

  defp apply_filter(filter, q) do
    case filter do
      {:id, {:not_eq, id}} ->
        where(q, [a], a.id != ^id)

      {:id, id} when is_integer(id) ->
        where(q, [a], a.id == ^id)

      {:user, %{id: user_id}} ->
        where(q, [a], a.user_id == ^user_id)

      {:user, user_id} when is_integer(user_id) ->
        where(q, [a], a.user_id == ^user_id)

      {:user, username} when is_binary(username) ->
        q
        |> ensure_user_join()
        |> where([user: u], fragment("lower(?)", u.username) == ^String.downcase(username))

      {:stream, %{id: stream_id}} ->
        where(q, [a], a.stream_id == ^stream_id)

      {:stream, stream_id} when is_integer(stream_id) ->
        where(q, [a], a.stream_id == ^stream_id)

      {:stream, true} ->
        where(q, [a], not is_nil(a.stream_id))

      {:stream, false} ->
        where(q, [a], is_nil(a.stream_id))

      {:stream, {:not_eq, stream_id}} ->
        where(q, [a], is_nil(a.stream_id) or a.stream_id != ^stream_id)

      {:stream, {:in, stream_ids}} ->
        where(q, [a], a.stream_id in ^stream_ids)

      {:full_text, {:search, text}} ->
        q
        |> ensure_fts_join()
        |> where(
          [fts: f],
          fragment(
            "(? || ? || coalesce(?, ''::tsvector)) @@ websearch_to_tsquery('simple', ?)",
            f.title_tsv,
            f.description_tsv,
            f.content_tsv,
            ^text
          )
        )

      {:title, {:search, text}} ->
        q
        |> ensure_fts_join()
        |> where([fts: f], fragment("? @@ websearch_to_tsquery('simple', ?)", f.title_tsv, ^text))

      {:token, token} ->
        where(q, [a], a.secret_token == ^token)

      :featured ->
        where(q, [a], a.featured == true)

      {:featured, true} ->
        where(q, [a], a.featured == true)

      {:featured, false} ->
        where(q, [a], a.featured != true or is_nil(a.featured))

      :popular ->
        q
        |> ensure_stats_inner_join()
        |> where([_a, stats_inner: s], s.popularity_score > 0.0)

      :public ->
        where(q, [a], a.visibility == :public)

      {:visibility, visibility} when visibility in [:public, :unlisted, :private] ->
        where(q, [a], a.visibility == ^visibility)

      {:created_at, condition} ->
        apply_field_condition(q, :inserted_at, condition)

      {:duration, condition} ->
        apply_field_condition(q, :duration, condition)

      {:compressed_size, condition} ->
        apply_field_condition(q, :compressed_size, condition)

      {:views, condition} ->
        q
        |> with_total_views()
        |> apply_views_condition(condition)

      {:audio, true} ->
        where(q, [a], not is_nil(a.audio_url))

      {:audio, false} ->
        where(q, [a], is_nil(a.audio_url))

      :snapshotless ->
        where(q, [a], is_nil(a.snapshot))
    end
  end

  defp sort(q, nil, _filters), do: q
  defp sort(q, :random, _filters), do: order_by(q, fragment("RANDOM()"))
  defp sort(q, {:created, :desc}, _filters), do: order_by(q, [a], desc: a.inserted_at, desc: a.id)
  defp sort(q, {:created, :asc}, _filters), do: order_by(q, [a], asc: a.inserted_at, asc: a.id)

  # duration is NOT NULL, so plain asc/desc lets one btree serve both directions
  defp sort(q, {:duration, :desc}, _filters),
    do: order_by(q, [a], desc: a.duration, desc: a.id)

  defp sort(q, {:duration, :asc}, _filters),
    do: order_by(q, [a], asc: a.duration, asc: a.id)

  defp sort(q, {:size, :desc}, _filters),
    do: order_by(q, [a], desc_nulls_last: a.compressed_size, desc: a.id)

  defp sort(q, {:size, :asc}, _filters),
    do: order_by(q, [a], asc_nulls_last: a.compressed_size, asc: a.id)

  defp sort(q, {:views, dir}, _filters) when dir in [:asc, :desc] do
    q
    |> with_total_views()
    |> order_by([a, stats_left: s], [{^dir, coalesce(s.total_views, 0)}, {^dir, a.id}])
  end

  defp sort(q, {:popularity, :desc}, _filters) do
    q
    |> ensure_stats_inner_join()
    |> order_by([a, stats_inner: s], desc: s.popularity_score, desc: s.popcast_id)
  end

  defp sort(q, {:rank, :desc}, filters) do
    case search_filter(filters) do
      {:full_text, text} ->
        q
        |> ensure_fts_join()
        |> order_by([fts: f],
          desc:
            fragment(
              "ts_rank_cd(setweight(?, 'A') || setweight(?, 'B') || setweight(coalesce(?, ''::tsvector), 'C'), websearch_to_tsquery('simple', ?), 4)",
              f.title_tsv,
              f.description_tsv,
              f.content_tsv,
              ^text
            )
        )

      {:title, text} ->
        q
        |> ensure_fts_join()
        |> order_by([fts: f],
          desc:
            fragment(
              "ts_rank_cd(setweight(?, 'A'), websearch_to_tsquery('simple', ?), 4)",
              f.title_tsv,
              ^text
            )
        )

      nil ->
        raise ArgumentError, "rank sort requires a supported search filter"
    end
  end

  defp ensure_stats_inner_join(q) do
    if has_named_binding?(q, :stats_inner) do
      q
    else
      join(q, :inner, [a], s in assoc(a, :stats), as: :stats_inner)
    end
  end

  defp ensure_stats_left_join(q) do
    if has_named_binding?(q, :stats_left) do
      q
    else
      join(q, :left, [a], s in assoc(a, :stats), as: :stats_left)
    end
  end

  defp apply_field_condition(q, field, {:eq, value}),
    do: where(q, [a], field(a, ^field) == ^value)

  defp apply_field_condition(q, field, {:gt, value}), do: where(q, [a], field(a, ^field) > ^value)

  defp apply_field_condition(q, field, {:gte, value}),
    do: where(q, [a], field(a, ^field) >= ^value)

  defp apply_field_condition(q, field, {:lt, value}), do: where(q, [a], field(a, ^field) < ^value)

  defp apply_field_condition(q, field, {:lte, value}),
    do: where(q, [a], field(a, ^field) <= ^value)

  defp apply_field_condition(q, field, {:between, from_value, to_value}),
    do: where(q, [a], field(a, ^field) >= ^from_value and field(a, ^field) <= ^to_value)

  defp apply_views_condition(q, {:eq, value}),
    do: where(q, [stats_left: s], coalesce(s.total_views, 0) == ^value)

  defp apply_views_condition(q, {:gt, value}),
    do: where(q, [stats_left: s], coalesce(s.total_views, 0) > ^value)

  defp apply_views_condition(q, {:gte, value}),
    do: where(q, [stats_left: s], coalesce(s.total_views, 0) >= ^value)

  defp apply_views_condition(q, {:lt, value}),
    do: where(q, [stats_left: s], coalesce(s.total_views, 0) < ^value)

  defp apply_views_condition(q, {:lte, value}),
    do: where(q, [stats_left: s], coalesce(s.total_views, 0) <= ^value)

  defp apply_views_condition(q, {:between, from_value, to_value}) do
    where(
      q,
      [stats_left: s],
      coalesce(s.total_views, 0) >= ^from_value and coalesce(s.total_views, 0) <= ^to_value
    )
  end

  defp ensure_fts_join(q) do
    if has_named_binding?(q, :fts) do
      q
    else
      join(q, :inner, [a], f in "popcast_fts", on: f.popcast_id == a.id, as: :fts)
    end
  end

  defp ensure_user_join(q) do
    if has_named_binding?(q, :user) do
      q
    else
      join(q, :inner, [a], u in assoc(a, :user), as: :user)
    end
  end

  defp search_filter(filters) do
    Enum.find_value(filters, fn
      {:full_text, {:search, text}} -> {:full_text, text}
      {:title, {:search, text}} -> {:title, text}
      _ -> nil
    end)
  end
end
