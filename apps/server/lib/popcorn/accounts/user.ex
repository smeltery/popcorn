defmodule Popcorn.Accounts.User do
  use Ecto.Schema

  schema "users" do
    field :username, :string
    field :temporary_username, :string
    field :email, :string
    field :name, :string
    field :timezone, :string
    field :auth_token, :string
    field :term_theme_name, :string
    field :term_theme_prefer_original, :boolean, default: true
    field :term_font_family, :string
    field :term_bold_is_bright, :boolean, default: false
    field :term_adaptive_palette, :boolean, default: false
    field :streaming_enabled, :boolean, default: true
    field :stream_recording_enabled, :boolean, default: true
    field :default_recording_visibility, Ecto.Enum, values: ~w[private unlisted public]a
    field :default_stream_visibility, Ecto.Enum, values: ~w[private unlisted public]a
    field :live_stream_limit, :integer
    field :last_login_at, :utc_datetime
    field :is_admin, :boolean
    field :recording_count, :integer, virtual: true
    field :stream_count, :integer, virtual: true

    timestamps(type: :utc_datetime)

    has_many :popcasts, Popcorn.Recordings.Popcast
    has_many :streams, Popcorn.Streaming.Stream
    has_many :clis, Popcorn.Accounts.Cli
  end
end

defimpl Phoenix.Param, for: Popcorn.Accounts.User do
  def to_param(%{username: username, id: id}) do
    username || "user:#{id}"
  end
end
