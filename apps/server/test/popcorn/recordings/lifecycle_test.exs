defmodule Popcorn.Recordings.LifecycleTest do
  use Popcorn.RecordingsCase, async: true

  describe "delete_popcast/1" do
    test "v1/v2" do
      popcast = insert(:popcast_v1) |> with_file()
      assert {:ok, _popcast} = Recordings.delete_popcast(popcast)

      popcast = insert(:popcast_v2) |> with_file()
      assert {:ok, _popcast} = Recordings.delete_popcast(popcast)
    end
  end

  describe "compress_popcast/1" do
    test "compresses a legacy popcast and backfills sizes" do
      popcast = insert(:popcast_v2) |> with_file("2/full.pop")
      old_path = popcast.path
      expected_uncompressed_size = File.stat!("test/fixtures/2/full.pop").size
      expected_event_count = Enum.count(Recordings.event_stream(popcast))

      assert {:ok, %{id: id}} = Recordings.compress_popcast(popcast)

      popcast = Recordings.get_popcast(id)
      stored_path = Recordings.get_cast_path!(popcast)

      assert popcast.compressed == true
      assert popcast.path =~ ~r|\.pop\.zst$|
      assert popcast.path != old_path
      assert popcast.uncompressed_size == expected_uncompressed_size
      assert popcast.compressed_size == File.stat!(stored_path).size
      assert Enum.count(Recordings.event_stream(popcast)) == expected_event_count
      assert Popcorn.FileStore.delete_file(old_path) == {:error, :enoent}
    end
  end

  describe "event_stream/1" do
    test "with popcast v1 file" do
      popcast = insert(:popcast_v1) |> with_file()

      stream = Recordings.event_stream(popcast)

      assert Enum.count(stream) == 785
    end

    test "with popcast v2 file" do
      popcast = insert(:popcast_v2) |> with_file()

      stream = Recordings.event_stream(popcast)

      assert Enum.count(stream) == 786
    end

    test "with zstd-compressed popcast file" do
      popcast =
        insert(:popcast_v2,
          compressed: true,
          path: "recordings/compressed/welcome.pop.zst"
        )

      path = zstd_fixture!("test/fixtures/welcome.pop")
      :ok = Popcorn.FileStore.put_file(popcast.path, path, "application/x-popcast")

      stream = Recordings.event_stream(popcast)

      assert Enum.count(stream) == 786
    end
  end

  describe "generate_snapshot/4" do
    @tag :vt
    test "returns list of screen lines" do
      output = [{1.0, "a"}, {2.4, "b"}, {2.6, "c"}]
      snapshot = Recordings.generate_snapshot(output, 4, 2, 2.5)

      assert snapshot ==
               {[
                  [{"ab  ", %{}, 1}],
                  [{"    ", %{}, 1}]
                ], {2, 0}}
    end
  end

  describe "generate_fts_content/3" do
    @tag :vt
    test "returns recording content prepared for FTS" do
      output = [{1.0, "o", "a"}, {2.4, "o", "B"}, {2.6, "o", "c"}]
      content = Recordings.generate_fts_content(output, 10, 5)

      assert content == "abc "
    end

    @tag :vt
    test "includes scrollback" do
      output = [{1.0, "o", "aaa\n"}, {2.4, "o", "Bbb\n"}, {2.6, "o", "ccc\n"}]
      content = Recordings.generate_fts_content(output, 10, 2)

      assert content == "aaa bbb ccc "
    end

    @tag :vt
    test "keeps words of len > 1, truncates words > 32" do
      output = [
        {1.0, "o", "a "},
        {2.4, "o", "bbbbbbbbbbBbbbbbbbbbbbbbbbbbbB "},
        {2.6, "o", "CcccccccccccccccccCcccccccccccccccccccCc "}
      ]

      content = Recordings.generate_fts_content(output, 100, 5)

      assert content == "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb cccccccccccccccccccccccccccccccc "
    end

    @tag :vt
    test "alt screen buffer" do
      output = [
        # print on primary buffer
        "nvim\r\n",
        # switch to alternate buffer
        "\x1b[?1047h",
        # print
        "hello ",
        # print
        "w",
        # print
        "o",
        # print
        "r",
        # print
        "l",
        # print
        "d",
        # move back 2 chars
        "\x08\x08",
        # print
        "mz",
        # print
        " planet",
        # move back to the beginning of "wormz"
        "\x1b[12D",
        # overwrite "wormz"
        "wyrm ",
        # enable insert mode
        "\x1b[4h",
        # insert "foo bar baz"
        " foo bar baz ",
        # switch back to primary buffer
        "\x1b[?1047l",
        # print
        "bye!"
      ]

      events = for {text, i} <- Enum.with_index(output), do: {i, "o", text}

      content = Recordings.generate_fts_content(events, 50, 10)

      assert content == "nvim bye world wormz hello wyrm foo bar baz planet "
    end
  end

  describe "update_fts_content/1" do
    test "small file" do
      popcast = insert(:popcast) |> with_file()

      assert Recordings.update_fts_content(popcast) == :ok
    end

    test "big file" do
      popcast = insert(:popcast_v3) |> with_file("big.pop")

      assert Recordings.update_fts_content(popcast) == :ok
    end
  end

  describe "register_view/1" do
    test "increments total_views on stats" do
      popcast = insert(:popcast)

      insert(:popcast_stats,
        popcast_id: popcast.id,
        total_views: 5,
        popularity_dirty: false
      )

      assert {:ok, :ok} = Recordings.register_view(popcast)

      stats = Repo.get!(PopcastStats, popcast.id)
      assert stats.total_views == 6
      assert stats.popularity_dirty == true
    end

    test "creates daily view record for today" do
      popcast = insert(:popcast)
      today = Date.utc_today()

      assert {:ok, :ok} = Recordings.register_view(popcast, today)

      [daily_view] =
        Repo.all(
          from(dv in "popcast_daily_views",
            where: dv.popcast_id == ^popcast.id and dv.date == ^today,
            select: %{date: dv.date, count: dv.count}
          )
        )

      assert daily_view.date == today
      assert daily_view.count == 1
    end

    test "increments existing daily view count for today" do
      popcast = insert(:popcast)
      today = Date.utc_today()

      Recordings.register_view(popcast, today)
      Recordings.register_view(popcast, today)
      Recordings.register_view(popcast, today)

      [daily_view] =
        Repo.all(
          from(dv in "popcast_daily_views",
            where: dv.popcast_id == ^popcast.id and dv.date == ^today,
            select: %{date: dv.date, count: dv.count}
          )
        )

      assert daily_view.count == 3
    end

    test "marks popcast as dirty for popularity recomputation" do
      popcast = insert(:popcast)

      insert(:popcast_stats,
        popcast_id: popcast.id,
        popularity_dirty: false
      )

      assert {:ok, :ok} = Recordings.register_view(popcast)

      stats = Repo.get!(PopcastStats, popcast.id)
      assert stats.popularity_dirty == true
    end
  end

  describe "recompute_popularity_scores/1" do
    test "recomputes only for dirty popcasts" do
      today = Date.utc_today()
      popcast = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: popcast.id, popularity_dirty: true)

      stale = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: stale.id, popularity_dirty: true)

      other = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: other.id, popularity_score: 9.9)

      Repo.insert_all("popcast_daily_views", [
        %{popcast_id: popcast.id, date: today, count: 4},
        %{popcast_id: stale.id, date: Date.add(today, -100), count: 9}
      ])

      assert {:ok, 1} = Recordings.recompute_popularity_scores(:dirty)

      popcast = Repo.get!(PopcastStats, popcast.id)
      stale = Repo.get!(PopcastStats, stale.id)
      other = Repo.get!(PopcastStats, other.id)

      assert popcast.popularity_score == 4.0
      assert stale.popularity_score == 0.0
      assert other.popularity_score == 9.9
      refute popcast.popularity_dirty
      refute stale.popularity_dirty
    end

    test "recomputes for all popcasts" do
      today = Date.utc_today()
      popcast = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: popcast.id, popularity_dirty: false)

      other = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: other.id, popularity_score: 5.5)

      Repo.insert_all("popcast_daily_views", [
        %{popcast_id: popcast.id, date: today, count: 3}
      ])

      assert {:ok, 1} = Recordings.recompute_popularity_scores(:all)

      popcast = Repo.get!(PopcastStats, popcast.id)
      other = Repo.get!(PopcastStats, other.id)

      assert popcast.popularity_score == 3.0
      assert other.popularity_score == 0.0
      refute popcast.popularity_dirty
      refute other.popularity_dirty
    end

    test "applies exponential decay to older views" do
      today = Date.utc_today()
      popcast = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: popcast.id, popularity_dirty: false)

      # Views from exactly 7 days ago (one half-life) should be halved
      # Views from exactly 14 days ago (two half-lives) should be quartered
      Repo.insert_all("popcast_daily_views", [
        %{popcast_id: popcast.id, date: today, count: 100},
        %{popcast_id: popcast.id, date: Date.add(today, -7), count: 100},
        %{popcast_id: popcast.id, date: Date.add(today, -14), count: 100}
      ])

      assert {:ok, 1} = Recordings.recompute_popularity_scores(:all)

      popcast = Repo.get!(PopcastStats, popcast.id)

      # Expected: 100 * 1.0 + 100 * 0.5 + 100 * 0.25 = 175.0
      assert popcast.popularity_score == 175.0
    end

    test "excludes archived popcasts from recomputation" do
      today = Date.utc_today()

      archived =
        insert(:popcast, visibility: :public, archived_at: DateTime.utc_now())

      insert(:popcast_stats,
        popcast_id: archived.id,
        popularity_score: 99.0,
        popularity_dirty: true
      )

      active = insert(:popcast, visibility: :public)
      insert(:popcast_stats, popcast_id: active.id, popularity_dirty: true)

      Repo.insert_all("popcast_daily_views", [
        %{popcast_id: archived.id, date: today, count: 50},
        %{popcast_id: active.id, date: today, count: 10}
      ])

      # Test :all scope
      assert {:ok, 1} = Recordings.recompute_popularity_scores(:all)

      archived = Repo.get!(PopcastStats, archived.id)
      active = Repo.get!(PopcastStats, active.id)

      # Archived should be untouched
      assert archived.popularity_score == 99.0
      assert archived.popularity_dirty == true

      # Active should be updated
      assert active.popularity_score == 10.0
      refute active.popularity_dirty
    end
  end

  describe "migrate_file/1" do
    test "is noop when the file path is up to date" do
      popcast =
        :popcast
        |> insert()
        |> with_file()
        |> Recordings.migrate_file()

      assert ^popcast = Recordings.migrate_file(popcast)
    end

    test "moves the file when the path is stale" do
      popcast =
        :popcast
        |> insert()
        |> with_file()

      old_path = popcast.path

      popcast = Recordings.migrate_file(popcast)

      assert popcast.path != old_path
    end
  end

  describe "unarchive/1" do
    test "clears archived_at and marks not archivable" do
      a = insert(:popcast, archived_at: ~U[2020-01-01 00:00:00Z], archivable: true)

      {:ok, updated} = Recordings.unarchive(a)
      assert is_nil(updated.archived_at)
      assert updated.archivable == false
    end
  end

  describe "archive/1" do
    test "stamps archived_at" do
      a = insert(:popcast, archived_at: nil)

      {:ok, archived} = Recordings.archive(a)
      assert %DateTime{} = archived.archived_at
    end
  end

  describe "count/1" do
    test "counts only recordings matching the spec (e.g. a user)" do
      user = insert(:user)
      other = insert(:user)
      insert_list(2, :popcast, user: user)
      insert(:popcast, user: other)

      assert Recordings.count(%Query{scope: :admin, archived: :include, filters: [user: user.id]}) ==
               2
    end
  end

  describe "byte_totals/1" do
    test "sums compressed and uncompressed sizes across the user's recordings" do
      u = insert(:user)
      insert(:popcast, user: u, compressed_size: 100, uncompressed_size: 1000)
      insert(:popcast, user: u, compressed_size: 250, uncompressed_size: 800)
      # other user's recording is excluded
      insert(:popcast, compressed_size: 99_999, uncompressed_size: 99_999)

      assert Recordings.byte_totals(u.id) == {350, 1800}
    end

    test "returns {nil, nil} when the user has no recordings" do
      u = insert(:user)
      assert Recordings.byte_totals(u.id) == {nil, nil}
    end
  end

  describe "recordings_by_day/1" do
    test "returns exactly N entries" do
      assert length(Recordings.recordings_by_day(10)) == 10
    end

    test "buckets recordings into today" do
      base = Recordings.recordings_by_day(2) |> List.last() |> elem(1)
      insert_list(3, :popcast)
      [{_today_date, today_count}] = Enum.take(Recordings.recordings_by_day(2), -1)
      assert today_count == base + 3
    end
  end
end
