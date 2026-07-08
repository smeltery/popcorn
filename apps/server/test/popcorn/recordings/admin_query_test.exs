defmodule Popcorn.Recordings.AdminQueryTest do
  use Popcorn.RecordingsCase, async: true

  describe "admin query execution" do
    test "includes recordings of every visibility, including archived" do
      user = insert(:user)
      insert(:popcast, user: user, visibility: :private)
      insert(:popcast, user: user, visibility: :unlisted)
      insert(:popcast, user: user, visibility: :public)
      insert(:popcast, user: user, archived_at: ~U[2025-01-01 00:00:00Z])

      results =
        %Query{scope: :admin, archived: :include, filters: [{:user, user}]}
        |> Recordings.list(1000)

      assert length(results) == 4
    end

    test "filters by visibility" do
      user = insert(:user)
      insert(:popcast, user: user, visibility: :private)
      insert(:popcast, user: user, visibility: :public)
      insert(:popcast, user: user, visibility: :public)

      results =
        %Query{
          scope: :admin,
          archived: :include,
          filters: [{:user, user}, {:visibility, :public}]
        }
        |> Recordings.list(1000)

      assert length(results) == 2
    end

    test "filters by archived" do
      insert(:popcast, archived_at: ~U[2024-12-01 00:00:00Z])
      insert(:popcast, archived_at: nil)
      insert(:popcast, archived_at: nil)

      assert length(Recordings.list(%Query{scope: :admin, archived: :only}, 1000)) == 1
    end

    test "filters by featured" do
      insert(:popcast, featured: true)
      insert(:popcast, featured: false)

      results =
        %Query{scope: :admin, archived: :include, filters: [{:featured, true}]}
        |> Recordings.list(1000)

      assert length(results) == 1
    end

    test "filters by user" do
      u = insert(:user)
      insert_list(2, :popcast, user: u)
      insert(:popcast)

      results =
        %Query{scope: :admin, archived: :include, filters: [{:user, u.id}]}
        |> Recordings.list(1000)

      assert length(results) == 2
    end

    test "search by title" do
      target = insert(:popcast, title: "My Demo Recording")
      insert(:popcast, title: "Unrelated")

      assert [%{id: id}] =
               %Query{scope: :admin, archived: :include, filters: [{:title, {:search, "demo"}}]}
               |> Recordings.list(10)

      assert id == target.id
    end

    test "filters by username" do
      u = insert(:user, username: "alicia")
      target = insert(:popcast, user: u)
      insert(:popcast)

      assert [%{id: id}] =
               %Query{scope: :admin, archived: :include, filters: [{:user, "alicia"}]}
               |> Recordings.list(10)

      assert id == target.id
    end

    test "respects limit" do
      insert_list(5, :popcast)
      assert length(Recordings.list(%Query{scope: :admin, archived: :include}, 2)) == 2
    end

    test "orders by created desc" do
      first = insert(:popcast)
      second = insert(:popcast)
      third = insert(:popcast)

      ids =
        %Query{scope: :admin, archived: :include, sort: {:created, :desc}}
        |> Recordings.list(3)
        |> Enum.map(& &1.id)
        |> Enum.filter(&(&1 in [first.id, second.id, third.id]))

      assert ids == [third.id, second.id, first.id]
    end

    test "sorts nullable sizes after known sizes" do
      user = insert(:user)
      unknown = insert(:popcast, user: user, compressed_size: nil)
      small = insert(:popcast, user: user, compressed_size: 100)
      large = insert(:popcast, user: user, compressed_size: 200)

      ids =
        %Query{
          scope: :admin,
          archived: :include,
          filters: [{:user, user.id}],
          sort: {:size, :desc}
        }
        |> Recordings.list(3)
        |> Enum.map(& &1.id)

      assert ids == [large.id, small.id, unknown.id]
    end

    test "paginates in display order" do
      first = insert(:popcast)
      second = insert(:popcast)
      third = insert(:popcast)

      page =
        %Query{scope: :admin, archived: :include, sort: {:created, :desc}}
        |> Recordings.paginate(1, 2)

      ids = Enum.map(page.entries, & &1.id)
      assert ids == [third.id, second.id]
      refute first.id in ids
    end
  end
end
