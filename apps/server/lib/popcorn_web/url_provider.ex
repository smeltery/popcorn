defmodule PopcornWeb.UrlProvider do
  use Phoenix.VerifiedRoutes,
    endpoint: PopcornWeb.Endpoint,
    router: PopcornWeb.Router

  @behaviour Popcorn.UrlProvider

  @impl true
  def sign_up(token) do
    url(~p"/users/new?t=#{token}")
  end

  @impl true
  def login(token) do
    url(~p"/session/new?t=#{token}")
  end

  @impl true
  def email_change(token) do
    url(~p"/user/email?t=#{token}")
  end

  @impl true
  def account_deletion(token) do
    url(~p"/user/delete?t=#{token}")
  end
end
