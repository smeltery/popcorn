defmodule Popcorn.Repo.Migrations.AddFtsToPopcasts do
  use Ecto.Migration

  def up do
    execute """
      ALTER TABLE popcasts
        ADD COLUMN title_tsv tsvector GENERATED ALWAYS AS (to_tsvector('simple', coalesce(title, ''))) STORED,
        ADD COLUMN description_tsv tsvector GENERATED ALWAYS AS (to_tsvector('simple', coalesce(description, ''))) STORED,
        ADD COLUMN content_tsv tsvector
    """

    execute "CREATE INDEX popcasts_fts_index ON popcasts USING GIN ((title_tsv || description_tsv || coalesce(content_tsv, ''::tsvector)))"

    %{}
    |> Oban.Job.new(worker: Popcorn.Workers.ReindexRecordings)
    |> Popcorn.Repo.insert!()
  end

  def down do
    execute "DROP INDEX popcasts_fts_index"

    execute """
      ALTER TABLE popcasts
        DROP COLUMN title_tsv,
        DROP COLUMN description_tsv,
        DROP COLUMN content_tsv
    """
  end
end
