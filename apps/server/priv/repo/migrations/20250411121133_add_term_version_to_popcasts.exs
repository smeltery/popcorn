defmodule Popcorn.Repo.Migrations.AddTermVersionToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :term_version, :string
    end
  end
end
