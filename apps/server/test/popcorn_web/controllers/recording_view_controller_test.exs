defmodule PopcornWeb.RecordingViewControllerTest do
  use PopcornWeb.ConnCase, async: true
  import Popcorn.Factory
  import Ecto.Query
  alias Popcorn.{Recordings, Repo}
  alias Popcorn.Recordings.PopcastStats

  describe "create" do
    test "increments view count with valid token", %{conn: conn} do
      popcast = insert(:popcast)

      insert(:popcast_stats,
        popcast_id: popcast.id,
        total_views: 5,
        popularity_dirty: false
      )

      token = Recordings.generate_view_count_token(popcast.id)

      conn = post(conn, ~p"/a/#{popcast}/views?token=#{token}")

      assert response(conn, 204)
      assert total_views(popcast.id) == 6
    end

    test "sets cookie to prevent double counting", %{conn: conn} do
      popcast = insert(:popcast)

      insert(:popcast_stats,
        popcast_id: popcast.id,
        total_views: 5,
        popularity_dirty: false
      )

      token = Recordings.generate_view_count_token(popcast.id)

      conn = post(conn, ~p"/a/#{popcast}/views?token=#{token}")

      assert response(conn, 204)
      assert conn.resp_cookies["a#{popcast.id}"]
    end

    test "does not increment when cookie already present", %{conn: conn} do
      popcast = insert(:popcast)

      insert(:popcast_stats,
        popcast_id: popcast.id,
        total_views: 5,
        popularity_dirty: false
      )

      token = Recordings.generate_view_count_token(popcast.id)

      conn =
        conn
        |> put_req_cookie("a#{popcast.id}", "1")
        |> post(~p"/a/#{popcast}/views?token=#{token}")

      assert response(conn, 204)
      assert total_views(popcast.id) == 5
    end

    test "ignores invalid token", %{conn: conn} do
      popcast = insert(:popcast)

      insert(:popcast_stats,
        popcast_id: popcast.id,
        total_views: 5,
        popularity_dirty: false
      )

      conn = post(conn, ~p"/a/#{popcast}/views?token=invalid")

      assert response(conn, 204)
      assert total_views(popcast.id) == 5
    end

    test "ignores token whose ID doesn't match the URL ID", %{conn: conn} do
      popcast = insert(:popcast)

      insert(:popcast_stats,
        popcast_id: popcast.id,
        total_views: 5,
        popularity_dirty: false
      )

      other_popcast = insert(:popcast)
      token = Recordings.generate_view_count_token(other_popcast.id)

      conn = post(conn, ~p"/a/#{popcast}/views?token=#{token}")

      assert response(conn, 204)
      assert total_views(popcast.id) == 5
    end

    test "ignores token for a non-existent popcast", %{conn: conn} do
      token = Recordings.generate_view_count_token(999_999)

      conn = post(conn, ~p"/a/999999/views?token=#{token}")

      assert response(conn, 204)
    end
  end

  defp total_views(popcast_id) do
    Repo.one(
      from(s in PopcastStats,
        where: s.popcast_id == ^popcast_id,
        select: s.total_views
      )
    )
  end
end
