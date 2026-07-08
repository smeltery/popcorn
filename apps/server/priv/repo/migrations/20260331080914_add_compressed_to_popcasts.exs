defmodule Popcorn.Repo.Migrations.AddCompressedToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :compressed, :boolean, null: false, default: false
    end
  end
end
