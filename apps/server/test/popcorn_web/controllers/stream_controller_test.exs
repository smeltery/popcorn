defmodule PopcornWeb.StreamControllerTest do
  use PopcornWeb.ConnCase, async: true
  import Popcorn.Factory

  describe "deleting" do
    test "requires author", %{conn: conn} do
      user = insert(:user)
      stream = insert(:stream, user: user)
      conn = log_in(conn, insert(:user))

      conn = delete(conn, ~p"/s/#{stream}")

      assert html_response(conn, 403)
    end
  end
end
