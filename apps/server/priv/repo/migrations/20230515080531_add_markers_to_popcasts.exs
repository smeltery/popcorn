defmodule Popcorn.Repo.Migrations.AddMarkersToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :markers, :text
    end
  end
end
