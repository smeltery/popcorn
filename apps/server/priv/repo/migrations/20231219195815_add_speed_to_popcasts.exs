defmodule Popcorn.Repo.Migrations.AddSpeedToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :speed, :float
    end
  end
end
