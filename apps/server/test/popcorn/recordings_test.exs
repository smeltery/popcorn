defmodule Popcorn.RecordingsTest do
  use Popcorn.DataCase, async: true
  import Popcorn.Factory
  import Popcorn.ZstdTestHelpers
  alias Popcorn.Recordings
  alias Popcorn.Recordings.{Popcast, PopcastStats, Query}

  describe "create_popcast/3" do
    test "json file, v1 format" do
      user = insert(:user)
      cli = insert(:cli, user: user)
      cli_id = cli.id
      upload = fixture(:upload, %{path: "1/full.json"})

      {:ok, popcast} =
        Recordings.create_popcast(user, upload.path, %{
          cli_id: cli_id,
          user_agent: "a/user/agent"
        })

      assert %Popcast{
               version: 1,
               compressed: true,
               command: "/bin/bash",
               duration: 10.370343,
               shell: "/bin/zsh",
               term_type: "screen-256color",
               term_cols: 96,
               term_rows: 26,
               title: "bashing :)",
               uname: nil,
               user_agent: "a/user/agent",
               cli_id: ^cli_id
             } = popcast

      assert popcast.path =~ ~r|^recordings/.+\.json\.zst$|
    end

    test "json file, v1 format (missing required data)" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "1/invalid.json"})

      assert {:error, %Ecto.Changeset{}} = Recordings.create_popcast(user, upload.path)
    end

    test "json file, unsupported version number" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "5/popcast.json"})

      assert {:error, {:invalid_version, 5}} = Recordings.create_popcast(user, upload.path)
    end

    test "rejects a recording with no events" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/no-events.pop"})

      assert {:error, :empty_recording} = Recordings.create_popcast(user, upload.path)
    end

    test "accepts a recording whose only event is at time zero" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/zero-time.pop"})

      assert {:ok, popcast} = Recordings.create_popcast(user, upload.path)
      assert popcast.duration === 0.0
    end

    test "cast file, v2 format, minimal" do
      user = insert(:user)
      cli = insert(:cli, user: user)
      cli_id = cli.id
      upload = fixture(:upload, %{path: "2/minimal.pop"})

      {:ok, popcast} =
        Recordings.create_popcast(user, upload.path, %{
          cli_id: cli_id,
          user_agent: "a/user/agent"
        })

      assert %Popcast{
               version: 2,
               compressed: true,
               term_cols: 96,
               term_rows: 26,
               term_type: nil,
               term_theme_fg: nil,
               term_theme_bg: nil,
               term_theme_palette: nil,
               duration: 8.456789,
               command: nil,
               recorded_at: nil,
               shell: nil,
               title: nil,
               idle_time_limit: nil,
               uname: nil,
               user_agent: "a/user/agent",
               cli_id: ^cli_id
             } = popcast

      assert popcast.path =~ ~r|^recordings/.+\.pop\.zst$|
    end

    test "cast file, v2 format, full" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.pop"})

      {:ok, popcast} =
        Recordings.create_popcast(user, upload.path, %{user_agent: "a/user/agent"})

      assert %Popcast{
               version: 2,
               compressed: true,
               term_cols: 96,
               term_rows: 26,
               duration: 7.34567,
               command: "/bin/bash -l",
               shell: "/bin/zsh",
               term_type: "screen-256color",
               title: "bashing :)",
               term_theme_fg: "#aaaaaa",
               term_theme_bg: "#bbbbbb",
               term_theme_palette:
                 "#151515:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#d0d0d0:#505050:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#f5f5f5",
               idle_time_limit: 2.5,
               uname: nil,
               user_agent: "a/user/agent"
             } = popcast

      assert popcast.path =~ ~r|^recordings/.+\.pop\.zst$|
      assert DateTime.to_unix(popcast.recorded_at) == 1_506_410_422
    end

    test "stores compressed and uncompressed file sizes for new uploads" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.pop"})
      expected_uncompressed_size = File.stat!(upload.path).size

      {:ok, popcast} = Recordings.create_popcast(user, upload.path)

      stored_path = Recordings.get_cast_path!(popcast)
      expected_compressed_size = File.stat!(stored_path).size

      assert popcast.uncompressed_size == expected_uncompressed_size
      assert popcast.compressed_size == expected_compressed_size
    end

    test "invalid file format" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "favicon.png"})

      assert {:error, :invalid_format} = Recordings.create_popcast(user, upload.path)
    end

    test "compressed upload" do
      user = insert(:user)

      zstd_path = zstd_fixture!("test/fixtures/2/full.pop")

      gzip_path = Briefly.create!()
      File.write!(gzip_path, :zlib.gzip(File.read!("test/fixtures/2/full.pop")))

      assert {:error, :invalid_format} = Recordings.create_popcast(user, zstd_path)
      assert {:error, :invalid_format} = Recordings.create_popcast(user, gzip_path)
    end

    test "syntax error in popcast v2 file" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/broken.pop"})

      assert {:error, :invalid_format} = Recordings.create_popcast(user, upload.path)
    end

    test "syntax error in popcast v3 file" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "3/broken.pop"})

      assert {:error, :invalid_format} = Recordings.create_popcast(user, upload.path)
    end

    test "default settings from user" do
      user =
        insert(:user,
          term_theme_name: nil,
          term_theme_prefer_original: false,
          term_bold_is_bright: false,
          term_adaptive_palette: false,
          default_recording_visibility: :public
        )

      upload = fixture(:upload, %{path: "3/full.pop"})
      {:ok, popcast} = Recordings.create_popcast(user, upload.path)

      assert %Popcast{
               term_theme_name: nil,
               term_font_family: nil,
               term_bold_is_bright: false,
               term_adaptive_palette: false,
               visibility: :public
             } = popcast

      user =
        insert(:user,
          term_theme_name: "dracula",
          term_theme_prefer_original: false,
          term_bold_is_bright: true,
          term_adaptive_palette: true,
          default_recording_visibility: :private
        )

      upload = fixture(:upload, %{path: "3/full.pop"})
      {:ok, popcast} = Recordings.create_popcast(user, upload.path)

      assert %Popcast{
               term_theme_name: nil,
               term_theme_palette: "#" <> _,
               term_bold_is_bright: true,
               term_adaptive_palette: true,
               visibility: :private
             } = popcast

      user =
        insert(:user,
          term_theme_name: "dracula",
          term_theme_prefer_original: true,
          default_recording_visibility: :private
        )

      upload = fixture(:upload, %{path: "3/full.pop"})
      {:ok, popcast} = Recordings.create_popcast(user, upload.path)

      assert %Popcast{
               term_theme_name: "original",
               term_theme_palette: "#" <> _,
               visibility: :private
             } = popcast
    end

    test "explicit terminal render options override user defaults" do
      user =
        insert(:user,
          term_bold_is_bright: false,
          term_adaptive_palette: false
        )

      upload = fixture(:upload, %{path: "3/full.pop"})

      {:ok, popcast} =
        Recordings.create_popcast(user, upload.path, %{
          term_bold_is_bright: true,
          term_adaptive_palette: true
        })

      assert %Popcast{
               term_bold_is_bright: true,
               term_adaptive_palette: true
             } = popcast
    end

    test "uses fresh username for path generation when user struct is stale" do
      user = insert(:user, username: "old-username")
      upload = fixture(:upload, %{path: "2/full.pop"})

      Repo.update_all(
        from(u in "users", where: u.id == ^user.id),
        set: [username: "new-username"]
      )

      {:ok, popcast} = Recordings.create_popcast(user, upload.path)

      assert popcast.path =~ "recordings/new-username/"
      refute popcast.path =~ "recordings/old-username/"
    end

    test "stores filename from params" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.pop"})

      {:ok, popcast} =
        Recordings.create_popcast(user, upload.path, %{}, %{"filename" => "my-recording.pop"})

      assert popcast.filename == "my-recording.pop"
    end

    test "strips path components from filename" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.pop"})

      {:ok, popcast} =
        Recordings.create_popcast(user, upload.path, %{}, %{
          "filename" => "../../etc/passwd/evil.pop"
        })

      assert popcast.filename == "evil.pop"
    end

    test "truncates very long filenames" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.pop"})
      long_name = String.duplicate("a", 1000) <> ".pop"

      {:ok, popcast} =
        Recordings.create_popcast(user, upload.path, %{}, %{"filename" => long_name})

      assert byte_size(popcast.filename) == 255
    end

    test "uses fallback filename when filename is missing" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.pop"})

      {:ok, popcast} = Recordings.create_popcast(user, upload.path)

      assert popcast.filename == "popcast.pop"
    end

    test "uses fallback filename when filename is not a binary" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.pop"})

      {:ok, popcast} =
        Recordings.create_popcast(user, upload.path, %{}, %{"filename" => 123})

      assert popcast.filename == "popcast.pop"
    end
  end

  describe "update_popcast/2" do
    test "updates the keystroke overlay setting" do
      popcast = insert(:popcast, keystroke_overlay: false)

      assert {:ok, %Popcast{keystroke_overlay: true}} =
               Recordings.update_popcast(popcast, %{"keystroke_overlay" => "true"})

      assert {:ok, %Popcast{keystroke_overlay: false}} =
               Recordings.update_popcast(popcast, %{"keystroke_overlay" => "false"})
    end

    test "updates the cursor mode setting" do
      popcast = insert(:popcast, term_cursor_mode: "blinking")

      assert {:ok, %Popcast{term_cursor_mode: "hidden"}} =
               Recordings.update_popcast(popcast, %{"term_cursor_mode" => "hidden"})

      assert {:error, changeset} =
               Recordings.update_popcast(popcast, %{"term_cursor_mode" => "bogus"})

      assert %{term_cursor_mode: _} = errors_on(changeset)
    end
  end

  describe "lookup_popcast/1" do
    test "accepts numerical ID for public recordings" do
      popcast = insert(:popcast, visibility: :public)
      id = popcast.id

      assert %Popcast{id: ^id} = Recordings.lookup_popcast(to_string(id))
      assert nil == Recordings.lookup_popcast("999999999999")
    end

    test "allows non-public lookup by numerical ID when enabled" do
      popcast = insert(:popcast, visibility: :unlisted)
      id = popcast.id

      assert nil == Recordings.lookup_popcast(to_string(id))

      assert %Popcast{id: ^id} =
               Recordings.lookup_popcast(to_string(id), allow_non_public_id: true)
    end

    test "accepts current 16-char secret tokens" do
      popcast = insert(:popcast, secret_token: "abcdefghijklmnop")
      id = popcast.id

      assert %Popcast{id: ^id} = Recordings.lookup_popcast("abcdefghijklmnop")

      assert nil == Recordings.lookup_popcast("zzzzzzzzzzzzzzzz")
    end

    test "accepts legacy 25-char secret tokens" do
      popcast = insert(:popcast, secret_token: "abcdefghijklmnopqrstuvwxy")
      id = popcast.id

      assert %Popcast{id: ^id} = Recordings.lookup_popcast("abcdefghijklmnopqrstuvwxy")

      assert nil == Recordings.lookup_popcast("zzzzzzzzzzzzzzzzzzzzzzzzz")
    end

    test "does not load snapshot by default" do
      snapshot = {[[{"test", %{}, 1}]], {0, 0}}
      popcast = insert(:popcast, visibility: :public, snapshot: snapshot)
      id = to_string(popcast.id)

      result = Recordings.lookup_popcast(id)
      assert result.id == popcast.id
      assert result.snapshot == nil
    end

    test "loads snapshot when load_snapshot: true" do
      snapshot = {[[{"test", %{}, 1}]], {0, 0}}
      popcast = insert(:popcast, visibility: :public, snapshot: snapshot)
      id = to_string(popcast.id)

      result = Recordings.lookup_popcast(id, load_snapshot: true)
      assert result.id == popcast.id
      assert %Popcorn.Recordings.Snapshot{} = result.snapshot
      assert length(result.snapshot.lines) == 1
    end
  end

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
