defmodule PopcornWeb.RecordingViewController do
  use PopcornWeb, :controller
  alias Popcorn.Recordings

  @cookie_max_age 3600 * 24

  def create(conn, %{"recording_id" => id, "token" => token}) do
    with {:ok, real_id} <- Recordings.verify_view_count_token(token),
         %{id: ^real_id} = popcast <- Recordings.lookup_popcast(id),
         key = "a#{popcast.id}",
         nil <- conn.req_cookies[key] do
      Recordings.register_view(popcast)
      put_resp_cookie(conn, key, "1", max_age: @cookie_max_age)
    else
      _ -> conn
    end
    |> send_resp(204, "")
  end
end
