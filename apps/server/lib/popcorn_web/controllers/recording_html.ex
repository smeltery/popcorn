defmodule PopcornWeb.RecordingHTML do
  use PopcornWeb, :html
  import PopcornWeb.ErrorHelpers
  alias Popcorn.{Accounts, Fonts, Media, Recordings, Themes}
  alias Popcorn.Recordings.{Markers, Snapshot}
  alias PopcornWeb.{MediaView, MediumHTML, RecordingSVG, UserHTML}

  embed_templates "recording_html/*"

  defdelegate author_username(popcast), to: MediaView
  defdelegate author_avatar_url(popcast), to: MediaView
  defdelegate author_profile_path(popcast), to: MediaView
  defdelegate theme(popcast), to: Media
  defdelegate term_theme_name(popcast), to: Media
  defdelegate theme_options(popcast), to: MediaView
  defdelegate font_family_options, to: MediaView
  defdelegate username(user), to: UserHTML
  defdelegate title(popcast), to: Recordings
  defdelegate env_info(popcast), to: MediumHTML

  def player_src(popcast), do: ~p"/a/#{popcast}" <> ".#{filename_ext(popcast)}"

  def player_opts(popcast, opts) do
    [
      cols: term_cols(popcast),
      rows: term_rows(popcast),
      theme: Media.term_theme_name(popcast),
      boldIsBright: popcast.term_bold_is_bright,
      adaptivePalette: popcast.term_adaptive_palette,
      terminalLineHeight: popcast.term_line_height,
      cursorMode: popcast.term_cursor_mode,
      customTerminalFontFamily: Media.font_family(popcast),
      keystrokeOverlay: popcast.keystroke_overlay,
      poster: poster(popcast.snapshot),
      markers: markers(popcast.markers),
      idleTimeLimit: popcast.idle_time_limit,
      speed: popcast.speed,
      audioUrl: popcast.audio_url
    ]
    |> Keyword.merge(opts)
    |> Ext.Keyword.rename(t: :startAt)
    |> Enum.into(%{})
  end

  def cinema_height(popcast) do
    MediaView.cinema_height(term_cols(popcast), term_rows(popcast))
  end

  def embed_script(popcast) do
    src = url(~p"/a/#{popcast}") <> ".js"
    id = "popcast-#{Phoenix.Param.to_param(popcast)}"

    {:safe, "<script src=\"#{src}\" id=\"#{id}\" async=\"true\"></script>"}
  end

  defp popcast_oembed_url(popcast, format) do
    url(~p"/oembed?#{%{url: url(~p"/a/#{popcast}"), format: format}}")
  end

  def duration(popcast), do: MediumHTML.format_duration(popcast.duration)

  defp poster(nil), do: nil

  defp poster(snapshot) do
    "data:text/plain," <> Snapshot.seq(snapshot)
  end

  defp markers(nil), do: nil

  defp markers(markers) do
    case Markers.parse(markers) do
      {:ok, markers} -> Enum.map(markers, &Tuple.to_list/1)
      {:error, _} -> nil
    end
  end

  def term_cols(popcast), do: popcast.term_cols_override || popcast.term_cols

  def term_rows(popcast), do: popcast.term_rows_override || popcast.term_rows

  def default_theme_display_name(popcast) do
    "Account default (#{Themes.display_name(Accounts.default_term_theme_name(popcast.user))})"
  end

  def default_font_display_name(user) do
    Fonts.display_name(Accounts.default_font_family(user) || "default")
  end

  defp short_text_description(popcast) do
    if popcast.description do
      popcast.description
      |> HtmlSanitizeEx.strip_tags()
      |> String.replace(~r/[\r\n]+/, " ")
      |> truncate(200)
    else
      "Recorded by #{author_username(popcast)}"
    end
  end

  defp env_info_attrs(popcast),
    do: Map.take(popcast, [:user_agent, :term_type, :term_version, :shell, :uname])

  defp truncate(text, length) do
    if String.length(text) > length do
      String.slice(text, 0, length - 3) <> "..."
    else
      text
    end
  end

  defp alternate_link_type(popcast) do
    case popcast.version do
      1 -> "application/popcast+json"
      2 -> "application/x-popcast"
      3 -> "application/x-popcast"
      _ -> nil
    end
  end

  def download_filename(popcast) do
    "#{popcast.id}.#{filename_ext(popcast)}"
  end

  def filename_ext(%{version: 1}), do: "json"
  def filename_ext(%{version: 2}), do: "pop"
  def filename_ext(%{version: 3}), do: "pop"

  def views_count(popcast) do
    case popcast.stats do
      nil -> 0
      %{total_views: total_views} -> total_views
    end
  end

  defp owned_by_current_user?(popcast, conn) do
    conn.assigns[:current_user] && conn.assigns[:current_user].id == popcast.user_id
  end

  def head("show.html", assigns), do: head_for_show(assigns)
  def head(_, _), do: nil
end
