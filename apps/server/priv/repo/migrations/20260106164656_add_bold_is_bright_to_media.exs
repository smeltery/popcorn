defmodule Popcorn.Repo.Migrations.AddBoldIsBright do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :term_bold_is_bright, :boolean, default: false, null: false
    end

    alter table(:popcasts) do
      add :term_bold_is_bright, :boolean, default: false, null: false
    end

    alter table(:streams) do
      add :term_bold_is_bright, :boolean, default: false, null: false
    end
  end
end
