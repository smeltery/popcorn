defmodule PopcornAdmin.RecordingHTML do
  use PopcornAdmin, :html

  alias Popcorn.Media
  alias Popcorn.Recordings.{Markers, Snapshot}

  embed_templates "recording_html/*"

  @doc "Cast file URL on the admin endpoint — same-origin, no visibility checks."
  def player_src(popcast) do
    ~p"/admin/recordings/#{popcast.id}/file"
  end

  @doc """
  Suggested filename for downloading the cast file: `username-id.ext`. The
  admin file endpoint serves the file decompressed, so no .zst suffix.
  """
  def download_filename(popcast) do
    ext = if popcast.version == 1, do: "json", else: "pop"
    "#{popcast.user.username || popcast.user_id}-#{popcast.id}.#{ext}"
  end

  @doc """
  Mirrors `PopcornWeb.RecordingHTML.player_opts/2` so the admin preview
  plays back like the public player.
  """
  def player_opts(popcast) do
    %{
      cols: popcast.term_cols_override || popcast.term_cols,
      rows: popcast.term_rows_override || popcast.term_rows,
      theme: Media.term_theme_name(popcast),
      boldIsBright: popcast.term_bold_is_bright,
      adaptivePalette: popcast.term_adaptive_palette,
      terminalLineHeight: popcast.term_line_height,
      customTerminalFontFamily: Media.font_family(popcast),
      poster: poster(popcast.snapshot),
      markers: markers(popcast.markers),
      idleTimeLimit: popcast.idle_time_limit,
      speed: popcast.speed,
      audioUrl: popcast.audio_url
    }
  end

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
end
