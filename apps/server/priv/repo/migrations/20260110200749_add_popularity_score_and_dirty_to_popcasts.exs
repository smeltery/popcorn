defmodule Popcorn.Repo.Migrations.AddPopularityScoreAndDirtyToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :popularity_score, :float, null: false, default: 0.0
      add :popularity_dirty, :boolean, null: false, default: false
    end

    create index(:popcasts, ["popularity_score DESC", "id DESC"],
      where: "visibility = 'public' AND popularity_score > 0.0 AND archived_at IS NULL"
    )

    create index(:popcasts, [:id], where: "popularity_dirty = true AND archived_at IS NULL")

    execute(fn ->
      %{}
      |> Oban.Job.new(worker: Popcorn.Workers.RecomputePopularityScores)
      |> Popcorn.Repo.insert!()
    end, "")
  end
end
