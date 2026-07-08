defmodule PopcornWeb.LayoutView do
  use PopcornWeb, :view
  import PopcornWeb.UserHTML, only: [avatar_url: 1]

  def page_title(conn) do
    title = conn.assigns[:page_title] || "Record and share your terminal sessions, the simple way"

    "#{title} - #{conn.host}"
  end

  def body_class(conn) do
    action = Phoenix.Controller.action_name(conn)

    controller =
      conn
      |> Phoenix.Controller.controller_module()
      |> Atom.to_string()
      |> String.replace(~r/(Elixir\.PopcornWeb\.)|(Controller)/, "")
      |> String.replace(".", "")
      |> Inflex.underscore()
      |> String.replace("_", " ")
      |> Inflex.parameterize()

    "c-#{controller} a-#{action}"
  end
end
