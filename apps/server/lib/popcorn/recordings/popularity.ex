defmodule Popcorn.Recordings.Popularity do
  import Ecto.Query, warn: false

  alias Popcorn.Repo
  alias Popcorn.Recordings.{Popcast, PopcastStats}

  @half_life_days 7
  @window_days 90

  def recompute_scores(scope \\ :all) do
    cutoff = Date.add(Date.utc_today(), -@window_days)

    decay_scores =
      from dv in "popcast_daily_views",
        where: dv.date >= ^cutoff,
        group_by: dv.popcast_id,
        select: %{
          popcast_id: dv.popcast_id,
          decay_score:
            fragment(
              "sum(? * power(0.5, (CURRENT_DATE - ?)::float / ?))",
              dv.count,
              dv.date,
              ^@half_life_days
            )
        }

    case scope do
      :all ->
        recompute_all(decay_scores, cutoff)

      :dirty ->
        recompute_dirty(decay_scores)
    end
  end

  def register_view(popcast, date \\ Date.utc_today()) do
    Repo.transact(fn ->
      Repo.insert_all(
        PopcastStats,
        [
          %{
            popcast_id: popcast.id,
            popularity_score: 0.0,
            total_views: 1,
            popularity_dirty: true
          }
        ],
        on_conflict: [inc: [total_views: 1], set: [popularity_dirty: true]],
        conflict_target: [:popcast_id]
      )

      Repo.insert_all(
        "popcast_daily_views",
        [%{popcast_id: popcast.id, date: date, count: 1}],
        on_conflict: [inc: [count: 1]],
        conflict_target: [:popcast_id, :date]
      )

      {:ok, :ok}
    end)
  end

  defp recompute_all(decay_scores, cutoff) do
    ids_with_views =
      from(dv in "popcast_daily_views",
        where: dv.date >= ^cutoff,
        distinct: true,
        select: dv.popcast_id
      )

    Repo.transact(
      fn ->
        # Update stats for popcasts with daily views in the window.
        {count, _} =
          from(s in PopcastStats,
            join: a in Popcast,
            on: a.id == s.popcast_id,
            join: ds in subquery(decay_scores),
            on: ds.popcast_id == s.popcast_id,
            where: is_nil(a.archived_at),
            update: [set: [popularity_score: ds.decay_score, popularity_dirty: false]]
          )
          |> Repo.update_all([])

        # Reset scores for non-archived stats without views in the window.
        Repo.update_all(
          from(s in PopcastStats,
            join: a in Popcast,
            on: a.id == s.popcast_id,
            where:
              is_nil(a.archived_at) and s.popcast_id not in subquery(ids_with_views) and
                (s.popularity_score > 0.0 or s.popularity_dirty == true)
          ),
          set: [popularity_score: 0.0, popularity_dirty: false]
        )

        {:ok, count}
      end,
      timeout: 5 * 60 * 1000
    )
  end

  defp recompute_dirty(decay_scores) do
    dirty_ids =
      from(s in PopcastStats,
        join: a in Popcast,
        on: a.id == s.popcast_id,
        where: s.popularity_dirty == true and is_nil(a.archived_at),
        select: s.popcast_id
      )

    decay_scores = from(dv in decay_scores, where: dv.popcast_id in subquery(dirty_ids))

    Repo.transact(
      fn ->
        # Update dirty stats for popcasts that have daily views in the window.
        {count, _} =
          from(s in PopcastStats,
            join: ds in subquery(decay_scores),
            on: ds.popcast_id == s.popcast_id,
            where: s.popcast_id in subquery(dirty_ids),
            update: [
              set: [
                popularity_score: ds.decay_score,
                popularity_dirty: false
              ]
            ]
          )
          |> Repo.update_all([])

        # Clear remaining dirty stats with no daily views.
        Repo.update_all(
          from(s in PopcastStats, where: s.popcast_id in subquery(dirty_ids)),
          set: [popularity_score: 0.0, popularity_dirty: false]
        )

        {:ok, count}
      end,
      timeout: 5 * 60 * 1000
    )
  end
end
