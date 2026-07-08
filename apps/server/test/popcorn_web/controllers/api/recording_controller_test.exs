defmodule PopcornWeb.Api.RecordingControllerTest do
  use PopcornWeb.ConnCase, async: true
  import Popcorn.Factory
  alias Popcorn.Accounts
  alias Popcorn.AppEnv
  alias Popcorn.Recordings

  setup(context) do
    [token: Map.get(context, :token, "9da34ff4-9bf7-45d4-aa88-98c933b15a3f")]
  end

  @recording_url ~r|^http://localhost:4001/a/[a-zA-Z0-9]{16}([a-zA-Z0-9]{9})?|
  @successful_response ~r|View.+at.+http://localhost:4001/a/[a-zA-Z0-9]{16}([a-zA-Z0-9]{9})?\n|s

  describe "create without authentication" do
    test "fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "3/minimal.pop"})

      conn = upload(conn, upload)

      assert %{"type" => "unauthenticated", "message" => "Missing installation ID"} =
               json_response(conn, 401)
    end
  end

  describe "create with invalid install ID" do
    setup [:authenticate]

    @tag token: "invalid-lol"
    test "fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "3/minimal.pop"})

      conn = upload(conn, upload)

      assert %{"type" => "unauthenticated", "message" => "Invalid installation ID"} =
               json_response(conn, 401)
    end
  end

  describe "create with revoked install ID" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "3/minimal.json"})

      conn = upload(conn, upload)

      assert %{"type" => "unauthenticated", "message" => "This installation ID has been revoked"} =
               json_response(conn, 401)
    end
  end

  describe "create via legacy path" do
    setup [:authenticate]

    test "succeeds", %{conn: conn} do
      conn = legacy_upload(conn, minimal_upload())

      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
      assert %{"url" => url, "message" => message} = json_response(conn, 201)
      assert url =~ @recording_url
      assert message =~ @successful_response
    end
  end

  describe "create with authentication" do
    setup [:authenticate]

    test "json file, v1 format succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/full.json"})

      conn = upload(conn, upload)

      assert List.first(get_resp_header(conn, "location")) =~ @recording_url

      assert %{
               "id" => id,
               "url" => url,
               "file_url" => file_url,
               "audio_url" => nil,
               "title" => "bashing :)",
               "description" => nil,
               "visibility" => "unlisted",
               "message" => message
             } = json_response(conn, 201)

      assert is_integer(id)
      assert url =~ @recording_url
      assert file_url =~ ~r/^http.+\.json$/
      assert message =~ @successful_response
    end

    test "json file, v2 format, minimal succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.pop"})

      conn = upload(conn, upload)

      assert List.first(get_resp_header(conn, "location")) =~ @recording_url

      assert %{
               "id" => id,
               "url" => url,
               "file_url" => file_url,
               "audio_url" => nil,
               "title" => nil,
               "description" => nil,
               "visibility" => "unlisted",
               "message" => message
             } = json_response(conn, 201)

      assert is_integer(id)
      assert url =~ @recording_url
      assert file_url =~ ~r/^http.+\.pop$/
      assert message =~ @successful_response
    end

    test "json file, v2 format, full succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/full.pop"})

      conn = upload(conn, upload)

      assert List.first(get_resp_header(conn, "location")) =~ @recording_url

      assert %{
               "id" => id,
               "url" => url,
               "file_url" => file_url,
               "audio_url" => nil,
               "title" => "bashing :)",
               "description" => nil,
               "visibility" => "unlisted",
               "message" => message
             } = json_response(conn, 201)

      assert is_integer(id)
      assert url =~ @recording_url
      assert file_url =~ ~r/^http.+\.pop$/
      assert message =~ @successful_response
    end

    test "json file, v1 format, missing required data fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/invalid.json"})

      conn = upload(conn, upload)

      assert %{
               "type" => "validation_failed",
               "message" => "Validation failed",
               "details" => [%{"field" => "term_cols", "message" => "can't be blank"}]
             } = json_response(conn, 422)
    end

    test "json file, v2 format, invalid theme format fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/invalid-theme.pop"})

      conn = upload(conn, upload)

      assert %{
               "type" => "validation_failed",
               "message" => "Validation failed",
               "details" => [%{"field" => "term_theme_bg"}, %{"field" => "term_theme_fg"}]
             } = json_response(conn, 422)
    end

    test "json file, unsupported version number fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "5/popcast.json"})

      conn = upload(conn, upload)

      assert %{
               "type" => "validation_failed",
               "message" => "popcast v5 is not supported"
             } = json_response(conn, 422)
    end

    test "non-json file fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "favicon.png"})

      conn = upload(conn, upload)

      assert %{
               "type" => "validation_failed",
               "message" => "This doesn't look like a valid popcast file"
             } = json_response(conn, 422)
    end

    test "requesting json response succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.pop"})
      conn = put_req_header(conn, "accept", "application/json")

      conn = upload(conn, upload)

      assert %{"url" => "http" <> _} = json_response(conn, 201)
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end

    test "stores user agent from request header", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.pop"})
      user_agent = "popcorn/3.0.0 target/x86_64-unknown-linux-gnu"

      conn =
        conn
        |> put_req_header("user-agent", user_agent)
        |> upload(upload)

      assert %{"id" => id} = json_response(conn, 201)
      assert Recordings.get_popcast(id).user_agent == user_agent
    end

    test "accepts title, description, visibility and audio_url params", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.pop"})

      params = %{
        "title" => "Upload title",
        "description" => "Upload description",
        "visibility" => "private",
        "audio_url" => "https://example.com/audio.opus"
      }

      conn = upload(conn, upload, params)

      assert %{
               "id" => id,
               "title" => "Upload title",
               "description" => "Upload description",
               "visibility" => "private",
               "audio_url" => "https://example.com/audio.opus"
             } = json_response(conn, 201)

      popcast = Recordings.get_popcast(id)

      assert popcast.title == "Upload title"
      assert popcast.description == "Upload description"
      assert popcast.visibility == :private
      assert popcast.audio_url == "https://example.com/audio.opus"
    end
  end

  describe "create with registered cli when registration is not required" do
    setup [:register_cli, :authenticate]

    test "succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "1/full.json"})

      conn = upload(conn, upload)
      response = json_response(conn, 201)

      assert response["url"] =~ @recording_url
      assert response["message"] =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end
  end

  describe "create with registered cli when registration is required" do
    setup [:require_registered_cli, :register_cli, :authenticate]

    test "succeeds", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.pop"})

      conn = upload(conn, upload)
      response = json_response(conn, 201)

      assert response["url"] =~ @recording_url
      assert response["message"] =~ @successful_response
      assert List.first(get_resp_header(conn, "location")) =~ @recording_url
    end
  end

  describe "create with non-registered cli when registration is required" do
    setup [:require_registered_cli, :authenticate]

    test "fails", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.pop"})

      conn = upload(conn, upload)

      assert %{"type" => "account_required", "message" => "This action requires an account"} =
               json_response(conn, 401)
    end

    @tag token: "not-a-uuid"
    test "fails with 401 for a malformed install ID", %{conn: conn} do
      upload = fixture(:upload, %{path: "2/minimal.pop"})

      conn = upload(conn, upload)

      assert %{"type" => "unauthenticated", "message" => "Invalid installation ID"} =
               json_response(conn, 401)
    end
  end

  describe "create with unregistered upload count limit and unregistered cli" do
    setup [:authenticate]

    test "allows uploads up to the limit, then rejects with 403", %{conn: conn} do
      AppEnv.put(Accounts, unregistered_upload_count_limit: 2)

      conn1 = upload(conn, minimal_upload())
      assert %{"url" => _} = json_response(conn1, 201)

      conn2 = upload(recycle(conn1), minimal_upload())
      assert %{"url" => _} = json_response(conn2, 201)

      conn3 = upload(recycle(conn2), minimal_upload())

      assert %{"type" => "upload_limit_reached", "message" => message} =
               json_response(conn3, 403)

      assert message =~ "Unregistered upload limit reached (2 recordings)"
    end

    test "counts archived recordings toward the limit", %{conn: conn} do
      AppEnv.put(Accounts, unregistered_upload_count_limit: 1)

      conn1 = upload(conn, minimal_upload())
      assert %{"id" => id} = json_response(conn1, 201)

      # hiding (archiving) the recording must not free up the quota
      {:ok, _} = Recordings.archive(Recordings.get_popcast(id))

      conn2 = upload(recycle(conn1), minimal_upload())
      assert %{"type" => "upload_limit_reached"} = json_response(conn2, 403)
    end
  end

  describe "create with unregistered upload count limit and registered cli" do
    setup [:register_cli, :authenticate]

    test "is not subject to the limit", %{conn: conn} do
      AppEnv.put(Accounts, unregistered_upload_count_limit: 1)

      conn1 = upload(conn, minimal_upload())
      assert %{"url" => _} = json_response(conn1, 201)

      conn2 = upload(recycle(conn1), minimal_upload())
      assert %{"url" => _} = json_response(conn2, 201)
    end
  end

  describe "create without unregistered upload count limit" do
    setup [:authenticate]

    test "allows unregistered cli to upload past the would-be limit", %{conn: conn} do
      conn1 = upload(conn, minimal_upload())
      assert %{"url" => _} = json_response(conn1, 201)

      conn2 = upload(recycle(conn1), minimal_upload())
      assert %{"url" => _} = json_response(conn2, 201)
    end
  end

  describe "create via legacy path with unregistered upload count limit" do
    setup [:authenticate]

    test "enforces the limit on the legacy /api/popcasts path too", %{conn: conn} do
      AppEnv.put(Accounts, unregistered_upload_count_limit: 1)

      conn1 = legacy_upload(conn, minimal_upload())
      assert %{"url" => _} = json_response(conn1, 201)

      conn2 = legacy_upload(recycle(conn1), minimal_upload())

      assert %{"type" => "upload_limit_reached"} = json_response(conn2, 403)
    end
  end

  describe "update without authentication" do
    test "fails", %{conn: conn} do
      popcast = insert(:popcast)

      conn = put(conn, ~p"/api/v1/recordings/#{popcast.id}", %{"title" => "New Title"})

      assert %{"type" => "unauthenticated", "message" => "Missing installation ID"} =
               json_response(conn, 401)
    end
  end

  describe "update with unknown install ID" do
    setup [:authenticate]

    test "fails", %{conn: conn} do
      popcast = insert(:popcast)

      conn = put(conn, ~p"/api/v1/recordings/#{popcast.id}", %{"title" => "New Title"})

      assert %{"type" => "account_required", "message" => "This action requires an account"} =
               json_response(conn, 401)
    end
  end

  describe "update with unregistered CLI" do
    setup [:register_cli, :authenticate]

    @tag user: [email: nil]
    test "fails", %{conn: conn} do
      popcast = insert(:popcast)

      conn = put(conn, ~p"/api/v1/recordings/#{popcast.id}", %{"title" => "New Title"})

      assert %{"type" => "account_required", "message" => "This action requires an account"} =
               json_response(conn, 401)
    end
  end

  describe "update with revoked install ID" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      popcast = insert(:popcast)

      conn = put(conn, ~p"/api/v1/recordings/#{popcast.id}", %{"title" => "New Title"})

      assert %{"type" => "unauthenticated", "message" => "This installation ID has been revoked"} =
               json_response(conn, 401)
    end
  end

  describe "update with registered CLI" do
    setup [:register_cli, :authenticate]

    test "succeeds when attrs are valid", %{conn: conn, cli: cli} do
      popcast =
        insert(:popcast,
          user: cli.user,
          title: "Original title",
          description: "Original description"
        )

      conn =
        put(conn, ~p"/api/v1/recordings/#{popcast.id}", %{
          "title" => "New title",
          "description" => "New description",
          "audio_url" => "https://example.com/audio.opus"
        })

      assert %{
               "id" => id,
               "url" => url,
               "file_url" => file_url,
               "audio_url" => "https://example.com/audio.opus",
               "title" => "New title",
               "description" => "New description",
               "visibility" => "unlisted"
             } = json_response(conn, 200)

      assert is_integer(id)
      assert url =~ @recording_url
      assert file_url =~ ~r/^http.+\.pop$/
    end

    test "succeeds when using secret token", %{conn: conn, cli: cli} do
      _popcast =
        insert(:popcast,
          user: cli.user,
          secret_token: "abcdefghijklmnop",
          title: "Original title"
        )

      conn =
        put(conn, ~p"/api/v1/recordings/abcdefghijklmnop", %{
          "title" => "New title via token"
        })

      assert %{
               "id" => id,
               "url" => url,
               "title" => "New title via token"
             } = json_response(conn, 200)

      assert is_integer(id)
      assert url =~ @recording_url
    end

    test "fails when attrs are not valid", %{conn: conn, cli: cli} do
      popcast = insert(:popcast, user: cli.user)

      conn = put(conn, ~p"/api/v1/recordings/#{popcast.id}", %{"term_cols_override" => 0})

      assert %{
               "type" => "validation_failed",
               "message" => "Validation failed",
               "details" => [
                 %{"field" => "term_cols_override", "message" => "must be greater than 0"}
               ]
             } = json_response(conn, 422)
    end

    test "fails when recording belongs to another user", %{conn: conn} do
      popcast = insert(:popcast)
      conn = put(conn, ~p"/api/v1/recordings/#{popcast.id}", %{"title" => "New Title"})

      assert %{"type" => "not_found", "message" => "Recording not found"} =
               json_response(conn, 404)
    end

    test "fails when recording is not found", %{conn: conn} do
      conn = put(conn, ~p"/api/v1/recordings/99999", %{"title" => "New Title"})

      assert %{"type" => "not_found", "message" => "Recording not found"} =
               json_response(conn, 404)
    end
  end

  describe "delete without authentication" do
    test "fails", %{conn: conn} do
      popcast = insert(:popcast)

      conn = delete(conn, ~p"/api/v1/recordings/#{popcast.id}")

      assert %{"type" => "unauthenticated", "message" => "Missing installation ID"} =
               json_response(conn, 401)
    end
  end

  describe "delete with unknown install ID" do
    setup [:authenticate]

    test "fails", %{conn: conn} do
      popcast = insert(:popcast)

      conn = delete(conn, ~p"/api/v1/recordings/#{popcast.id}")

      assert %{"type" => "account_required", "message" => "This action requires an account"} =
               json_response(conn, 401)
    end
  end

  describe "delete with unregistered CLI" do
    setup [:register_cli, :authenticate]

    @tag user: [email: nil]
    test "fails", %{conn: conn} do
      popcast = insert(:popcast)

      conn = delete(conn, ~p"/api/v1/recordings/#{popcast.id}")

      assert %{"type" => "account_required", "message" => "This action requires an account"} =
               json_response(conn, 401)
    end
  end

  describe "delete with revoked install ID" do
    setup [:register_cli, :revoke_cli, :authenticate]

    test "fails", %{conn: conn} do
      popcast = insert(:popcast)

      conn = delete(conn, ~p"/api/v1/recordings/#{popcast.id}")

      assert %{"type" => "unauthenticated", "message" => "This installation ID has been revoked"} =
               json_response(conn, 401)
    end
  end

  describe "delete with registered CLI" do
    setup [:register_cli, :authenticate]

    test "succeeds when deleting own recording", %{conn: conn, cli: cli} do
      popcast = insert(:popcast, user: cli.user)

      conn = delete(conn, ~p"/api/v1/recordings/#{popcast.id}")

      assert response(conn, 204) == ""
    end

    test "succeeds when deleting own recording using secret token", %{conn: conn, cli: cli} do
      _popcast = insert(:popcast, user: cli.user, secret_token: "abcdefghijklmnop")

      conn = delete(conn, ~p"/api/v1/recordings/abcdefghijklmnop")

      assert response(conn, 204) == ""
    end

    test "fails when recording belongs to another user", %{conn: conn} do
      popcast = insert(:popcast)
      conn = delete(conn, ~p"/api/v1/recordings/#{popcast.id}")

      assert %{"type" => "not_found", "message" => "Recording not found"} =
               json_response(conn, 404)
    end

    test "fails when recording is not found", %{conn: conn} do
      conn = delete(conn, ~p"/api/v1/recordings/99999")

      assert %{"type" => "not_found", "message" => "Recording not found"} =
               json_response(conn, 404)
    end
  end

  defp upload(conn, upload, params \\ %{}) do
    conn
    |> put_resp_content_type("application/json")
    |> post(~p"/api/v1/recordings", Map.put(params, "file", upload))
  end

  defp minimal_upload, do: fixture(:upload, %{path: "2/minimal.pop"})

  defp legacy_upload(conn, upload) do
    conn
    |> put_resp_content_type("application/json")
    |> post(~p"/api/popcasts", %{"popcast" => upload})
  end

  defp require_registered_cli(_context) do
    AppEnv.put(Popcorn.Accounts, upload_auth_required: true)

    :ok
  end

  defp register_cli(%{token: token} = context) do
    user = insert(:user, Map.get(context, :user, []))
    cli = insert(:cli, user: user, token: token)

    [cli: cli]
  end

  defp revoke_cli(%{cli: cli}) do
    [cli: Accounts.revoke_cli!(cli)]
  end

  defp authenticate(%{conn: conn, token: token}) do
    conn =
      if token do
        put_req_header(conn, "authorization", "Basic " <> Base.encode64("test:" <> token))
      else
        conn
      end

    [conn: conn]
  end
end
