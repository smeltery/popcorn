defmodule Popcorn.Repo.Migrations.AddThemeFieldsToPopcast do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :theme_fg, :string
      add :theme_bg, :string
      add :theme_palette, :string
    end
  end
end
