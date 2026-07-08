defmodule PopcornWeb.DefaultAvatar do
  @type url :: String.t()
  @type user :: Popcorn.User.t()

  @callback url(user) :: url

  def url(user) do
    Keyword.fetch!(Application.fetch_env!(:popcorn, __MODULE__), :adapter).url(user)
  end
end
