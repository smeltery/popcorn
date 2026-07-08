defmodule Popcorn.Recordings.Popcast do
  use Ecto.Schema
  alias __MODULE__

  schema "popcasts" do
    field :version, :integer
    field :filename, :string
    field :path, :string
    field :term_cols, :integer
    field :term_cols_override, :integer
    field :term_rows, :integer
    field :term_rows_override, :integer
    field :term_type, :string
    field :term_version, :string
    field :term_theme_name, :string
    field :term_theme_fg, :string
    field :term_theme_bg, :string
    field :term_theme_palette, :string
    field :term_bold_is_bright, :boolean, default: false
    field :term_adaptive_palette, :boolean, default: false
    field :term_line_height, :float
    field :term_font_family, :string
    field :term_cursor_mode, :string, default: "blinking"
    field :keystroke_overlay, :boolean, default: false
    field :visibility, Ecto.Enum, values: ~w[private unlisted public]a, default: :unlisted
    field :featured, :boolean
    field :secret_token, :string
    field :duration, :float
    field :title, :string
    field :description, :string
    field :snapshot_at, :float
    field :snapshot, Popcorn.Ecto.Type.Snapshot, load_in_query: false
    field :command, :string
    field :shell, :string
    field :uname, :string
    field :user_agent, :string
    field :recorded_at, :utc_datetime
    field :idle_time_limit, :float
    field :speed, :float
    field :archivable, :boolean, default: true
    field :archived_at, :utc_datetime
    field :markers, :string
    field :env, :map
    field :audio_url, :string
    field :compressed, :boolean, default: false
    field :compressed_size, :integer
    field :uncompressed_size, :integer
    field :total_views, :integer, virtual: true

    field :stream_id, :id

    timestamps(type: :utc_datetime)

    belongs_to :user, Popcorn.Accounts.User
    belongs_to :cli, Popcorn.Accounts.Cli
    has_one :stats, Popcorn.Recordings.PopcastStats, foreign_key: :popcast_id
  end

  defimpl Phoenix.Param do
    def to_param(%Popcast{visibility: :public} = popcast), do: Integer.to_string(popcast.id)
    def to_param(%Popcast{} = popcast), do: popcast.secret_token
  end
end
