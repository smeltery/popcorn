defmodule Popcorn.Repo.Migrations.AddDefaultPopcastVisibilityToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :default_popcast_visibility, :popcast_visibility, null: false, default: "unlisted"
    end

    execute "UPDATE users SET default_popcast_visibility = 'public' WHERE NOT popcasts_private_by_default"

    alter table(:users) do
      remove :popcasts_private_by_default
    end
  end

  def down do
    alter table(:users) do
      add :popcasts_private_by_default, :boolean, null: false, default: true
    end

    execute "UPDATE users SET popcasts_private_by_default = FALSE WHERE default_popcast_visibility = 'public'"

    alter table(:users) do
      remove :default_popcast_visibility
    end
  end
end
