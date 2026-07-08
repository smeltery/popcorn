defmodule Popcorn.Recordings.CreateUpdateLookupTest do
  use Popcorn.RecordingsCase, async: true

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
end
