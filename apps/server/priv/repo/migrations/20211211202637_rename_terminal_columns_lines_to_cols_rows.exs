defmodule Popcorn.Repo.Migrations.RenameTerminalColumnsLinesToColsRows do
  use Ecto.Migration

  def change do
    rename table(:popcasts), :terminal_columns, to: :cols
    rename table(:popcasts), :terminal_lines, to: :rows
  end
end
