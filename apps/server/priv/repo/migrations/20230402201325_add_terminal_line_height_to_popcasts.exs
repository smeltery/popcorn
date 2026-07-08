defmodule Popcorn.Repo.Migrations.AddTerminalLineHeightToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :terminal_line_height, :float
    end
  end
end
