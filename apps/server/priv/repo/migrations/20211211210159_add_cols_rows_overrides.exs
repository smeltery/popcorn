defmodule Popcorn.Repo.Migrations.AddColsRowsOverrides do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :cols_override, :integer
      add :rows_override, :integer
    end
  end
end
