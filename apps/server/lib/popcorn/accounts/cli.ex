defmodule Popcorn.Accounts.Cli do
  use Ecto.Schema

  schema "clis" do
    field :token, :string
    field :revoked_at, :utc_datetime

    timestamps(type: :utc_datetime)

    belongs_to :user, Popcorn.Accounts.User
    has_many :popcasts, Popcorn.Recordings.Popcast
  end
end
