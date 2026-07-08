defmodule PopcornWeb.WebFingerJSON do
  use PopcornWeb, :json

  def show(%{user: %{username: username}, domain: domain}) do
    %{
      subject: "acct:#{username}@#{domain}",
      aliases: [
        url(~p"/~#{username}")
      ],
      links: [
        %{
          rel: "http://webfinger.net/rel/profile-page",
          type: "text/html",
          href: url(~p"/~#{username}")
        }
      ]
    }
  end
end
