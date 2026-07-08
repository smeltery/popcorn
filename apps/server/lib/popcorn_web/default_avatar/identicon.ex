defmodule PopcornWeb.DefaultAvatar.Identicon do
  use Phoenix.VerifiedRoutes,
    endpoint: PopcornWeb.Endpoint,
    router: PopcornWeb.Router

  @behaviour PopcornWeb.DefaultAvatar

  @impl true
  def url(user) do
    ~p"/~#{user}/avatar"
  end
end
