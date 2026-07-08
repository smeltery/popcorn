defmodule Popcorn.Repo.Migrations.AddKeystrokeOverlayToMedia do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :keystroke_overlay, :boolean, default: false, null: false
    end

    alter table(:streams) do
      add :keystroke_overlay, :boolean, default: false, null: false
    end
  end
end
