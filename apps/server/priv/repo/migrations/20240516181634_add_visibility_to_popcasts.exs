defmodule Popcorn.Repo.Migrations.AddVisibilityToPopcasts do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE popcast_visibility AS ENUM ('private', 'unlisted', 'public')")

    alter table(:popcasts) do
      add :visibility, :popcast_visibility, null: false, default: "unlisted"
    end

    execute "UPDATE popcasts SET visibility = 'public' WHERE NOT private"

    alter table(:popcasts) do
      remove :private
    end
  end

  def down do
    alter table(:popcasts) do
      add :private, :boolean, null: false, default: true
    end

    execute "UPDATE popcasts SET private = FALSE WHERE visibility = 'public'"

    alter table(:popcasts) do
      remove :visibility
    end

    execute("DROP TYPE popcast_visibility")
  end
end
