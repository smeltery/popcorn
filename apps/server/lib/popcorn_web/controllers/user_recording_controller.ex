defmodule PopcornWeb.UserRecordingController do
  use PopcornWeb, :controller
  alias Popcorn.{Accounts, Recordings}
  alias Popcorn.Recordings.Query, as: RecordingQuery
  alias PopcornWeb.FallbackController

  plug :load_user

  def index(conn, params) do
    user = conn.assigns.user
    current_user = conn.assigns.current_user
    self = !!(current_user && current_user.id == user.id)

    popcasts =
      %RecordingQuery{
        scope: {:listing_for, current_user},
        filters: [{:user, user}],
        sort: {:created, :desc}
      }
      |> Recordings.paginate(params["page"], 14, pagination_opts(conn, owner_id: user.id))

    render(
      conn,
      "index.html",
      page_title: "#{user.username}'s profile",
      user: user,
      self: self,
      popcasts: popcasts
    )
  end

  defp load_user(conn, _opts) do
    if user = Accounts.find_user_by_profile_id(conn.params["username"]) do
      assign(conn, :user, user)
    else
      conn
      |> FallbackController.call({:error, :not_found})
      |> halt()
    end
  end
end
