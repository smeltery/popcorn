defmodule Popcorn.Repo.Migrations.AddPopcastFtsTitleIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  # The existing GIN covers only the title/description/content concatenation;
  # title-only searches need their own.
  def change do
    create index(:popcast_fts, [:title_tsv],
             name: "popcast_fts_title_index",
             using: "GIN",
             concurrently: true
           )
  end
end
