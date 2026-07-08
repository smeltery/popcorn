defmodule Popcorn.Repo.Migrations.CreatePopcastStats do
  use Ecto.Migration

  def up do
    create table(:popcast_stats, primary_key: false) do
      add :popcast_id, references(:popcasts, on_delete: :delete_all),
        primary_key: true,
        null: false

      add :total_views, :integer, null: false, default: 0
      add :popularity_score, :float, null: false, default: 0.0
      add :popularity_dirty, :boolean, null: false
    end

    create index(:popcasts, ["id DESC"],
      where: "visibility = 'public' AND archived_at IS NULL",
      name: "popcasts_public_non_archived_index"
    )

    create index(:popcast_stats, ["popularity_score DESC", "popcast_id DESC"],
      where: "popularity_score > 0.0",
      name: "popcast_stats_popular_index"
    )

    create index(:popcast_stats, [:popcast_id], where: "popularity_dirty = true")

    execute """
    INSERT INTO popcast_stats (popcast_id, popularity_score, total_views, popularity_dirty)
    SELECT id, popularity_score, views_count, popularity_dirty
    FROM popcasts;
    """

    alter table(:popcasts) do
      remove :popularity_score
      remove :popularity_dirty
      remove :views_count
    end
  end

  def down do
    alter table(:popcasts) do
      add :popularity_score, :float, null: false, default: 0.0
      add :popularity_dirty, :boolean, null: false, default: false
      add :views_count, :integer, null: false, default: 0
    end

    execute """
    UPDATE popcasts
    SET popularity_score = s.popularity_score,
        popularity_dirty = s.popularity_dirty,
        views_count = s.total_views
    FROM popcast_stats s
    WHERE popcasts.id = s.popcast_id;
    """

    create index(:popcasts, ["popularity_score DESC", "id DESC"],
      where: "visibility = 'public' AND popularity_score > 0.0 AND archived_at IS NULL"
    )

    create index(:popcasts, [:id], where: "popularity_dirty = true AND archived_at IS NULL")

    create index(:popcasts, [:views_count], name: "index_popcasts_on_views_count")

    drop index(:popcasts, ["id DESC"], name: "popcasts_public_non_archived_index")

    drop table(:popcast_stats)
  end
end
