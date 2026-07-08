defmodule Popcorn.Repo.Migrations.AddIndexForSnapshotlessPopcasts do
  use Ecto.Migration

  def change do
    create index(:popcasts, ["(1)"], where: "snapshot IS NULL", name: "popcasts_snapshotless_index")
  end
end
