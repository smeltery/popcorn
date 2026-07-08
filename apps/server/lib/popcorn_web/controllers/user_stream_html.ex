defmodule PopcornWeb.UserStreamHTML do
  use PopcornWeb, :html

  embed_templates "user_stream_html/*"

  defdelegate profile_link(user), to: PopcornWeb.UserHTML
  defdelegate username(user), to: PopcornWeb.UserHTML
end
