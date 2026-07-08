defmodule Popcorn.Recordings.PopcastStats do
  use Ecto.Schema
  alias Popcorn.Recordings.Popcast

  @primary_key {:popcast_id, :id, autogenerate: false}
  schema "popcast_stats" do
    field :total_views, :integer
    field :popularity_score, :float
    field :popularity_dirty, :boolean

    belongs_to :popcast, Popcast, define_field: false
  end
end
