defmodule PopcornWeb.OembedJSON do
  use PopcornWeb, :json
  alias PopcornWeb.UserHTML
  alias Phoenix.HTML.Tag

  def show(%{popcast: popcast, max_width: mw, max_height: mh}) do
    attrs(popcast, mw, mh)
  end

  @cell_width 7.22
  @cell_height 16
  @border_width 12
  # pixel density
  @scale 2

  defp attrs(popcast, max_width, max_height) do
    cols = popcast.term_cols_override || popcast.term_cols
    rows = popcast.term_rows_override || popcast.term_rows

    image_width =
      (@scale * (@cell_width * cols + @border_width))
      |> Float.floor()
      |> round()

    image_height =
      (@scale * (@cell_height * rows + @border_width))
      |> round()

    {width, height} =
      size_smaller_than(
        image_width,
        image_height,
        max_width || image_width,
        max_height || image_height
      )

    recording_url = url(~p"/a/#{popcast}")
    thumbnail_url = recording_url <> ".png"

    %{
      type: "rich",
      version: 1.0,
      title: popcast.title,
      author_name: UserHTML.username(popcast.user),
      author_url: url(~p"/~#{popcast.user}"),
      provider_name: "popcorn",
      provider_url: url(~p"/"),
      thumbnail_url: thumbnail_url,
      thumbnail_width: width,
      thumbnail_height: height,
      html: html(recording_url, thumbnail_url, popcast.title, width),
      width: width,
      height: height
    }
  end

  defp html(recording_url, thumbnail_url, title, width) do
    safe =
      Tag.content_tag :a, href: recording_url, target: "_blank" do
        Tag.img_tag(thumbnail_url, alt: title, width: width)
      end

    Phoenix.HTML.safe_to_string(safe)
  end

  defp size_smaller_than(width, height, max_width, max_height) do
    fw = max_width / width
    fh = max_height / height

    if fw > 1 && fh > 1 do
      {width, height}
    else
      f = min(fw, fh)
      {round(width * f), round(height * f)}
    end
  end
end
