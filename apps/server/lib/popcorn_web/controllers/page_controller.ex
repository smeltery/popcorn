defmodule PopcornWeb.PageController do
  use PopcornWeb, :controller

  def about(conn, _params) do
    render(
      conn,
      "about.html",
      page_title: "About",
      contact_email_address: Application.get_env(:popcorn, :contact_email_address),
      server_name: PopcornWeb.Endpoint.host(),
      server_version: Application.get_env(:popcorn, :version)
    )
  end
end
