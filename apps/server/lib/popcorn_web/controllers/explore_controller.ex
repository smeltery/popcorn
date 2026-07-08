defmodule PopcornWeb.ExploreController do
  use PopcornWeb, :controller
  alias Popcorn.{Recordings, Streaming}
  alias Popcorn.Recordings.Query, as: RecordingQuery
  alias Popcorn.Streaming.Query, as: StreamQuery

  def show(conn, _params) do
    live_streams = fetch_live_streams()
    upcoming_streams = fetch_upcoming_streams()
    featured_popcasts = fetch_featured_popcasts()
    popular_popcasts = fetch_popular_popcasts()

    recent_popcasts =
      fetch_recent_popcasts([
        live_streams,
        upcoming_streams,
        featured_popcasts,
        popular_popcasts
      ])

    assigns = [
      page_title: "Explore",
      live_streams: live_streams,
      upcoming_streams: upcoming_streams,
      featured_popcasts: featured_popcasts,
      popular_popcasts: popular_popcasts,
      recent_popcasts: recent_popcasts
    ]

    render(conn, "show.html", assigns)
  end

  defp fetch_live_streams do
    %StreamQuery{scope: :public_listing, filters: [:live], sort: :recently_started}
    |> list_streams(2)
  end

  defp fetch_upcoming_streams do
    %StreamQuery{scope: :public_listing, filters: [:upcoming], sort: :soonest}
    |> list_streams(2)
  end

  defp fetch_featured_popcasts do
    %RecordingQuery{scope: :public_listing, filters: [:featured], sort: :random}
    |> list_popcasts(2)
  end

  @popular_pool_size 50
  @popular_limit 2

  defp fetch_popular_popcasts do
    seed = div(DateTime.to_unix(DateTime.utc_now()), 60)

    popcasts =
      %RecordingQuery{scope: :public_listing, filters: [:popular], sort: {:popularity, :desc}}
      |> Recordings.list(@popular_pool_size)
      |> Enum.sort_by(fn popcast -> :erlang.phash2({popcast.id, seed}) end)

    %{
      items: Enum.take(popcasts, @popular_limit),
      has_more: length(popcasts) > @popular_limit
    }
  end

  defp fetch_recent_popcasts(earlier_sections) do
    used_rows =
      Enum.reduce(earlier_sections, 0, fn section, acc ->
        case section do
          %{items: []} -> acc
          %{items: _} -> acc + 1
        end
      end)

    limit = (5 - used_rows) * 2

    %RecordingQuery{scope: :public_listing, sort: {:created, :desc}}
    |> list_popcasts(limit)
  end

  def featured_recordings(conn, params) do
    popcasts =
      %RecordingQuery{scope: :public_listing, filters: [:featured], sort: {:created, :desc}}
      |> Recordings.paginate(params["page"], 14, pagination_opts(conn))

    assigns = [
      page_title: "Featured recordings",
      popcasts: popcasts
    ]

    render(conn, "featured_recordings.html", assigns)
  end

  def popular_recordings(conn, params) do
    popcasts =
      %RecordingQuery{scope: :public_listing, filters: [:popular], sort: {:popularity, :desc}}
      |> Recordings.paginate(params["page"], 14, pagination_opts(conn))

    assigns = [
      page_title: "Popular recordings",
      popcasts: popcasts
    ]

    render(conn, "popular_recordings.html", assigns)
  end

  def recent_recordings(conn, params) do
    popcasts =
      %RecordingQuery{scope: :public_listing, sort: {:created, :desc}}
      |> Recordings.paginate(params["page"], 14, pagination_opts(conn))

    assigns = [
      page_title: "Recent recordings",
      popcasts: popcasts
    ]

    render(conn, "recent_recordings.html", assigns)
  end

  def live_streams(conn, params) do
    streams =
      %StreamQuery{scope: :public_listing, filters: [:live], sort: :recently_started}
      |> Streaming.paginate(params["page"], 14, pagination_opts(conn))

    assigns = [
      page_title: "Live streams",
      streams: streams
    ]

    render(conn, "live_streams.html", assigns)
  end

  def upcoming_streams(conn, params) do
    streams =
      %StreamQuery{scope: :public_listing, filters: [:upcoming], sort: :soonest}
      |> Streaming.paginate(params["page"], 14, pagination_opts(conn))

    assigns = [
      page_title: "Upcoming streams",
      streams: streams
    ]

    render(conn, "upcoming_streams.html", assigns)
  end

  defp list_streams(query, limit) do
    items = Streaming.list(query, limit + 1)

    %{
      items: Enum.take(items, limit),
      has_more: length(items) > limit
    }
  end

  defp list_popcasts(query, limit) do
    items = Recordings.list(query, limit + 1)

    %{
      items: Enum.take(items, limit),
      has_more: length(items) > limit
    }
  end
end
