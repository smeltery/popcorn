defmodule Popcorn.Repo.Migrations.CreatePopcastFts do
  use Ecto.Migration

  def up do
    create table(:popcast_fts, primary_key: false) do
      add :popcast_id, references(:popcasts, on_delete: :delete_all),
        primary_key: true,
        null: false

      add :title_tsv, :tsvector, null: false
      add :description_tsv, :tsvector, null: false
      add :content_tsv, :tsvector
    end

    execute """
    INSERT INTO popcast_fts (popcast_id, title_tsv, description_tsv, content_tsv)
    SELECT id, title_tsv, description_tsv, content_tsv
    FROM popcasts;
    """

    execute """
    CREATE INDEX popcast_fts_index
    ON popcast_fts
    USING GIN ((title_tsv || description_tsv || coalesce(content_tsv, ''::tsvector)));
    """

    execute """
    CREATE OR REPLACE FUNCTION upsert_popcast_fts()
    RETURNS trigger
    LANGUAGE plpgsql AS
    $$
    BEGIN
      INSERT INTO popcast_fts (popcast_id, title_tsv, description_tsv)
      VALUES (
        NEW.id,
        to_tsvector('simple', coalesce(NEW.title, '')),
        to_tsvector('simple', coalesce(NEW.description, ''))
      )
      ON CONFLICT (popcast_id) DO UPDATE
        SET title_tsv = EXCLUDED.title_tsv,
            description_tsv = EXCLUDED.description_tsv;

      RETURN NEW;
    END;
    $$;
    """

    execute """
    CREATE TRIGGER trg_popcast_fts_upsert
    AFTER INSERT OR UPDATE OF title, description ON popcasts
    FOR EACH ROW
    EXECUTE FUNCTION upsert_popcast_fts();
    """
  end

  def down do
    execute """
    DROP TRIGGER IF EXISTS trg_popcast_fts_upsert ON popcasts;
    """

    execute """
    DROP FUNCTION IF EXISTS upsert_popcast_fts();
    """

    execute "DROP INDEX popcast_fts_index"
    drop table(:popcast_fts)
  end
end
