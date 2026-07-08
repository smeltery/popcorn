defmodule PopcornWeb.UserRecordingHTML do
  use PopcornWeb, :html
  alias PopcornWeb.RecordingHTML

  embed_templates "user_recording_html/*"

  defdelegate profile_link(user), to: PopcornWeb.UserHTML
  defdelegate username(user), to: PopcornWeb.UserHTML
end
