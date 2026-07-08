defmodule Popcorn.Repo.Migrations.DropFtsFromPopcasts do
  use Ecto.Migration

  def up do
    execute "DROP INDEX popcasts_fts_index"

    execute """
    ALTER TABLE popcasts
      DROP COLUMN title_tsv,
      DROP COLUMN description_tsv,
      DROP COLUMN content_tsv
    """
  end

  def down do
    execute """
      ALTER TABLE popcasts
        ADD COLUMN title_tsv tsvector GENERATED ALWAYS AS (to_tsvector('simple', coalesce(title, ''))) STORED,
        ADD COLUMN description_tsv tsvector GENERATED ALWAYS AS (to_tsvector('simple', coalesce(description, ''))) STORED,
        ADD COLUMN content_tsv tsvector
    """

    execute """
    UPDATE popcasts
    SET content_tsv = f.content_tsv
    FROM popcast_fts f
    WHERE popcasts.id = f.popcast_id;
    """

    execute """
    CREATE INDEX popcasts_fts_index
    ON popcasts
    USING GIN ((title_tsv || description_tsv || coalesce(content_tsv, ''::tsvector)));
    """
  end
end
