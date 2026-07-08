defmodule PopcornWeb.Api.RecordingController do
  use PopcornWeb, :controller
  use Popcorn.Config
  alias Popcorn.{Recordings, Accounts}
  alias PopcornWeb.Api.AuthError
  alias PopcornWeb.Plug.Authz

  plug :assign_install_id
  plug :assign_cli
  plug :enforce_upload_limit when action in [:create]
  plug :require_registered_cli when action in [:update, :delete]
  plug :load_popcast when action in [:update, :delete]

  def create(conn, %{"popcast" => %Plug.Upload{}} = params),
    do: create(conn, Map.pop(params, "popcast"))

  def create(conn, %{"file" => %Plug.Upload{}} = params),
    do: create(conn, Map.pop(params, "file"))

  def create(conn, {upload, params}) do
    cli = conn.assigns.cli
    user_agent = get_user_agent(conn)
    params = Map.put(params, "filename", upload.filename)

    case Recordings.create_popcast(
           cli.user,
           upload.path,
           %{cli_id: cli.id, user_agent: user_agent},
           params
         ) do
      {:ok, popcast} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", url(~p"/a/#{popcast}"))
        |> render(:show, popcast: popcast)

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, reason: reason)
    end
  end

  def update(conn, params) do
    popcast = conn.assigns.popcast

    case Recordings.update_popcast(popcast, params) do
      {:ok, popcast} ->
        render(conn, :show, popcast: popcast)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, reason: changeset)
    end
  end

  def delete(conn, _params) do
    popcast = conn.assigns.popcast
    {:ok, _} = Recordings.delete_popcast(popcast)

    send_resp(conn, :no_content, "")
  end

  defp get_user_agent(conn) do
    conn
    |> get_req_header("user-agent")
    |> List.first()
  end

  defp assign_install_id(conn, _opts) do
    case get_basic_auth(conn) do
      {username, install_id} ->
        conn
        |> assign(:install_id, install_id)
        |> assign(:username, username)

      _otherwise ->
        AuthError.render_error(conn, :missing)
    end
  end

  defp assign_cli(conn, _opts) do
    %{install_id: install_id, username: username} = conn.assigns

    with {:ok, cli} <- Accounts.get_or_create_upload_cli(username, install_id) do
      conn
      |> assign(:cli, cli)
      |> assign(:current_user, cli.user)
    else
      {:error, reason} ->
        AuthError.render_error(conn, cli_error_kind(reason))
    end
  end

  defp cli_error_kind(:token_invalid), do: :invalid
  defp cli_error_kind(:token_not_found), do: :no_account
  defp cli_error_kind(:cli_revoked), do: :revoked

  defp enforce_upload_limit(conn, _opts) do
    cli = conn.assigns.cli
    limit = Accounts.unregistered_upload_count_limit()

    if limit && !Accounts.cli_registered?(cli) &&
         Recordings.count_user_popcasts(cli.user) >= limit do
      conn
      |> put_status(:forbidden)
      |> render(:error,
        reason: :upload_limit,
        message:
          "Unregistered upload limit reached (#{limit} #{if limit == 1, do: "recording", else: "recordings"})"
      )
      |> halt()
    else
      conn
    end
  end

  defp require_registered_cli(conn, _opts) do
    if Accounts.cli_registered?(conn.assigns.cli) do
      conn
    else
      AuthError.render_error(conn, :no_account)
    end
  end

  defp load_popcast(conn, _) do
    id = String.trim(conn.params["id"])

    with popcast when not is_nil(popcast) <-
           Recordings.lookup_popcast(id, allow_non_public_id: true),
         true <- Authz.authorized?(conn, popcast) do
      assign(conn, :popcast, popcast)
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> render(:error, reason: :not_found)
        |> halt()
    end
  end
end
