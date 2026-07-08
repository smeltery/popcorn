defmodule PopcornAdmin.RedirectController do
  use PopcornAdmin, :controller

  def to_admin(conn, _params), do: redirect(conn, to: ~p"/admin")
end
