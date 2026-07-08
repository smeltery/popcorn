defmodule Popcorn.Repo.Migrations.AddArchivedAtToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :archived_at, :naive_datetime
    end
  end
end
