defmodule Popcorn.Recordings.QueryTest do
  use Popcorn.RecordingsCase, async: true

  describe "query/1" do
    test "requires an explicit scope" do
      assert_raise ArgumentError, fn ->
        struct!(Query, filters: [])
      end
    end

    test "applies public and listing scopes" do
      owner = insert(:user)
      viewer = insert(:user)

      public = insert(:popcast, user: owner, visibility: :public)
      unlisted = insert(:popcast, user: owner, visibility: :unlisted)
      private = insert(:popcast, user: owner, visibility: :private)

      public_ids =
        %Query{scope: :public_listing}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      viewer_ids =
        %Query{scope: {:listing_for, viewer}}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      anonymous_ids =
        %Query{scope: {:listing_for, nil}}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      owner_ids =
        %Query{scope: {:listing_for, owner}}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      assert public.id in public_ids
      refute unlisted.id in public_ids
      refute private.id in public_ids

      assert Enum.sort(public_ids) == Enum.sort(viewer_ids)
      assert Enum.sort(public_ids) == Enum.sort(anonymous_ids)
      assert public.id in owner_ids
      assert unlisted.id in owner_ids
      assert private.id in owner_ids
    end

    test "applies archived mode" do
      active = insert(:popcast, archived_at: nil)
      archived = insert(:popcast, archived_at: ~U[2025-01-01 00:00:00Z])

      exclude_ids =
        %Query{scope: :system, archived: :exclude}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      include_ids =
        %Query{scope: :system, archived: :include}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      only_ids =
        %Query{scope: :system, archived: :only}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      assert active.id in exclude_ids
      refute archived.id in exclude_ids

      assert active.id in include_ids
      assert archived.id in include_ids

      refute active.id in only_ids
      assert archived.id in only_ids
    end

    test "filters by token (exact secret_token match)" do
      target = insert(:popcast, secret_token: "tok-target-aaaaaaaa")
      insert(:popcast, secret_token: "tok-other-bbbbbbbbbb")

      results =
        %Query{scope: :admin, archived: :include, filters: [{:token, "tok-target-aaaaaaaa"}]}
        |> Recordings.list(10)

      assert Enum.map(results, & &1.id) == [target.id]
    end

    test "filters by user, id exclusion, featured, and snapshotless" do
      user = insert(:user)
      other_user = insert(:user)

      target =
        insert(:popcast,
          user: user,
          featured: true,
          snapshot: nil
        )

      excluded =
        insert(:popcast,
          user: user,
          featured: true,
          snapshot: nil
        )

      insert(:popcast, user: other_user, featured: true, snapshot: nil)
      insert(:popcast, user: user, featured: false, snapshot: nil)
      insert(:popcast, user: user, featured: true)

      results =
        %Query{
          scope: :system,
          filters: [
            {:user, user},
            {:id, {:not_eq, excluded.id}},
            :featured,
            :snapshotless
          ]
        }
        |> Recordings.list(10)

      assert Enum.map(results, & &1.id) == [target.id]
    end

    test "filters by stream relation" do
      user = insert(:user)
      stream = insert(:stream)
      other_stream = insert(:stream)

      target = insert(:popcast, user: user, stream_id: stream.id)
      excluded = insert(:popcast, user: user, stream_id: other_stream.id)
      without_stream = insert(:popcast, user: user, stream_id: nil)

      assert_ids = fn stream_filter, ids ->
        results =
          %Query{scope: :system, filters: [{:user, user}, stream_filter]}
          |> Recordings.list(10)

        assert Enum.map(results, & &1.id) |> Enum.sort() == Enum.sort(ids)
      end

      assert_ids.({:stream, stream}, [target.id])
      assert_ids.({:stream, stream.id}, [target.id])
      assert_ids.({:stream, true}, [target.id, excluded.id])
      assert_ids.({:stream, false}, [without_stream.id])
      assert_ids.({:stream, {:not_eq, other_stream.id}}, [target.id, without_stream.id])
      assert_ids.({:stream, {:in, [stream.id]}}, [target.id])
    end

    test "filters by id, public status, featured false, and audio presence" do
      user = insert(:user)

      public_audio =
        insert(:popcast,
          user: user,
          visibility: :public,
          featured: false,
          audio_url: "https://example.com/audio"
        )

      private = insert(:popcast, user: user, visibility: :private, featured: nil)
      public_featured = insert(:popcast, user: user, visibility: :public, featured: true)

      assert_ids = fn filter, expected ->
        ids =
          %Query{
            scope: :system,
            archived: :include,
            filters: [{:user, user.id}, filter]
          }
          |> Recordings.list(10)
          |> Enum.map(& &1.id)
          |> Enum.sort()

        assert ids == Enum.sort(expected)
      end

      assert_ids.({:id, private.id}, [private.id])
      assert_ids.(:public, [public_audio.id, public_featured.id])
      assert_ids.({:featured, false}, [public_audio.id, private.id])
      assert_ids.({:audio, true}, [public_audio.id])
      assert_ids.({:audio, false}, [private.id, public_featured.id])
    end

    test "filters by created time, duration, size, and views" do
      user = insert(:user)

      low =
        insert(:popcast,
          user: user,
          inserted_at: ~U[2025-01-01 00:00:00Z],
          duration: 10,
          compressed_size: 100
        )

      high =
        insert(:popcast,
          user: user,
          inserted_at: ~U[2025-02-01 00:00:00Z],
          duration: 20,
          compressed_size: 200
        )

      insert(:popcast_stats, popcast_id: low.id, total_views: 5)
      insert(:popcast_stats, popcast_id: high.id, total_views: 15)

      assert_id = fn filter, expected ->
        assert [%{id: id}] =
                 %Query{
                   scope: :system,
                   archived: :include,
                   filters: [{:user, user.id}, filter]
                 }
                 |> Recordings.list(10)

        assert id == expected.id
      end

      assert_id.({:created_at, {:gte, ~U[2025-01-15 00:00:00Z]}}, high)
      assert_id.({:duration, {:between, 15, 25}}, high)
      assert_id.({:compressed_size, {:lt, 150}}, low)
      assert_id.({:views, {:gte, 10}}, high)
    end

    test "views filters count recordings without stats as zero views" do
      user = insert(:user)
      unviewed = insert(:popcast, user: user)
      viewed = insert(:popcast, user: user)
      insert(:popcast_stats, popcast_id: viewed.id, total_views: 5)

      list = fn filter ->
        %Query{scope: :system, archived: :include, filters: [{:user, user.id}, filter]}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)
        |> Enum.sort()
      end

      assert list.({:views, {:eq, 0}}) == [unviewed.id]
      assert list.({:views, {:lt, 3}}) == [unviewed.id]
      assert list.({:views, {:gt, 0}}) == [viewed.id]
      assert list.({:views, {:between, 1, 10}}) == [viewed.id]
    end

    test "smoke-tests random sort" do
      user = insert(:user)

      insert(:popcast, user: user)
      insert(:popcast, user: user, stream_id: insert(:stream).id)

      results =
        %Query{scope: :system, filters: [{:user, user}], sort: :random}
        |> Recordings.list(10)

      assert length(results) == 2
    end

    test "searches title and full text" do
      title_match = insert(:popcast, title: "Deploy Demo", description: "nothing")
      description_match = insert(:popcast, title: "Other", description: "Deploy notes")

      content_match =
        insert(:popcast_v3, title: "Other", description: "nothing")
        |> with_file()

      insert(:popcast, title: "Other", description: "nothing")

      assert Recordings.update_fts_content(content_match) == :ok

      title_results =
        %Query{scope: :system, filters: [{:title, {:search, "deploy"}}]}
        |> Recordings.list(10)

      title_description_results =
        %Query{scope: :system, filters: [{:full_text, {:search, "deploy"}}]}
        |> Recordings.list(10)

      content_results =
        %Query{scope: :system, filters: [{:full_text, {:search, "foo"}}]}
        |> Recordings.list(10)

      title_description_ids =
        title_description_results
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert Enum.map(title_results, & &1.id) == [title_match.id]
      assert title_description_ids == Enum.sort([title_match.id, description_match.id])
      assert Enum.map(content_results, & &1.id) == [content_match.id]
    end

    test "rank sort requires a search filter" do
      assert_raise ArgumentError, fn ->
        %Query{scope: :system, sort: {:rank, :desc}}
        |> Recordings.list(10)
      end
    end

    test "filters popular recordings to public items with positive scores" do
      popular = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: popular.id, popularity_score: 1.0)

      zero = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: zero.id, popularity_score: 0.0)

      private = insert(:popcast, visibility: :private)
      insert(:popcast_stats, popcast_id: private.id, popularity_score: 2.0)

      archived = insert(:popcast, visibility: :public, archived_at: DateTime.utc_now())
      insert(:popcast_stats, popcast_id: archived.id, popularity_score: 3.0)

      results =
        %Query{scope: :public_listing, filters: [:popular]}
        |> Recordings.list(10)

      assert Enum.map(results, & &1.id) == [popular.id]
    end

    test "orders by popularity score then id" do
      low = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: low.id, popularity_score: 5.0)

      mid = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: mid.id, popularity_score: 5.0)

      high = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: high.id, popularity_score: 10.0)

      results =
        %Query{scope: :public_listing, filters: [:popular], sort: {:popularity, :desc}}
        |> Recordings.list(10)

      assert Enum.map(results, & &1.id) == [high.id, mid.id, low.id]
    end
  end

  describe "paginate/4" do
    test "caps total entries and pages when max_pages is set" do
      user = insert(:user)
      insert_list(21, :popcast, visibility: :public, user: user)

      page =
        %Query{scope: :system, filters: [{:user, user}], sort: {:created, :desc}}
        |> Recordings.paginate(11, 2, max_pages: 10)

      assert page.total_pages == 10
      assert page.total_entries == 20
      assert page.page_number == 10
      assert length(page.entries) == 2
    end

    test "doesn't cap pages when max_pages is not set" do
      user = insert(:user)
      insert_list(21, :popcast, visibility: :public, user: user)

      page =
        %Query{scope: :system, filters: [{:user, user}], sort: {:created, :desc}}
        |> Recordings.paginate(11, 2)

      assert page.total_pages > 10
      assert page.page_number == 11
      assert page.total_entries == 21
    end
  end
end
