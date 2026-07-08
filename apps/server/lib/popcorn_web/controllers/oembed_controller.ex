defmodule PopcornWeb.OembedController do
  use PopcornWeb, :controller
  alias Popcorn.Recordings
  alias PopcornWeb.Authorization

  plug :put_layout, nil

  def show(conn, params) do
    with {:ok, path} <- parse_url(params["url"] || ""),
         {:ok, id} <- extract_id(path),
         {:ok, popcast} <- load_and_authorize_popcast(id) do
      {mw, mh} = get_size(params)
      format = get_embed_format(conn)

      render(
        conn,
        "show.#{format}",
        popcast: popcast,
        max_width: mw,
        max_height: mh
      )
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp load_and_authorize_popcast(id) do
    case Recordings.lookup_popcast(id) do
      nil ->
        {:error, :not_found}

      popcast ->
        if Authorization.can?(nil, :show, popcast) do
          {:ok, popcast}
        else
          if Recordings.secret_token?(id), do: {:error, :forbidden}, else: {:error, :not_found}
        end
    end
  end

  defp parse_url(url) do
    case URI.parse(url).path do
      nil -> {:error, :bad_request}
      path -> {:ok, path}
    end
  end

  defp extract_id(path) do
    case Regex.run(~r|^/a/([^/]+)$|, path) do
      [_, id] -> {:ok, id}
      _ -> {:error, :bad_request}
    end
  end

  defp get_size(params) do
    mw = if params["maxwidth"], do: String.to_integer(params["maxwidth"])
    mh = if params["maxheight"], do: String.to_integer(params["maxheight"])

    {mw, mh}
  end

  defp get_embed_format(conn) do
    case conn.params["format"] || get_format(conn) do
      "xml" -> "xml"
      _ -> "json"
    end
  end
end
