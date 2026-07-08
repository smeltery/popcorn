defmodule PopcornWeb.UrlHelpers do
  use Phoenix.VerifiedRoutes,
    endpoint: PopcornWeb.Endpoint,
    router: PopcornWeb.Router

  alias PopcornWeb.Endpoint

  def popcast_file_url(popcast) do
    url(~p"/a/#{popcast}") <> "." <> ext(popcast)
  end

  defp ext(popcast) do
    case popcast.version do
      1 -> "json"
      2 -> "pop"
      3 -> "pop"
    end
  end

  @http_to_ws %{"http" => "ws", "https" => "wss"}

  def ws_producer_url(stream) do
    uri = Endpoint.struct_url()
    scheme = @http_to_ws[uri.scheme]
    path = "/ws/S/#{stream.producer_token}"

    to_string(%{uri | scheme: scheme, path: path})
  end

  def ws_public_url(stream) do
    uri = Endpoint.struct_url()
    scheme = @http_to_ws[uri.scheme]
    param = Phoenix.Param.to_param(stream)
    path = "/ws/s/#{param}"

    to_string(%{uri | scheme: scheme, path: path})
  end
end
