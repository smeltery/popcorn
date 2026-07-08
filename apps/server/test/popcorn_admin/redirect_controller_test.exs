defmodule PopcornAdmin.RedirectControllerTest do
  use PopcornAdmin.ConnCase, async: true

  test "GET / redirects to /admin", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert redirected_to(conn) == ~p"/admin"
  end
end
