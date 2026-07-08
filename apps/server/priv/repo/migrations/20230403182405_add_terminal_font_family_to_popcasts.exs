defmodule Popcorn.Repo.Migrations.AddTerminalFontFamilyToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :terminal_font_family, :string
    end
  end
end
