defmodule Popcorn.Repo.Migrations.AddIndexOnPopcastsVisibility do
  use Ecto.Migration

  def change do
    create index(:popcasts, [:visibility])
  end
end
