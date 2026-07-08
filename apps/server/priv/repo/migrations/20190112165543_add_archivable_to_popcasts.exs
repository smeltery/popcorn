defmodule Popcorn.Repo.Migrations.AddArchivableToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :archivable, :boolean, null: false, default: true
    end
  end
end
