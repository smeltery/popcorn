defmodule Popcorn.Repo.Migrations.AddStreamIdToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :stream_id, references(:streams)
    end

    create index(:popcasts, [:stream_id])
  end
end
