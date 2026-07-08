defmodule Popcorn.Workers.RecomputeDirtyPopularityScores do
  use Oban.Worker, unique: [period: 300, states: :incomplete]

  alias Popcorn.Recordings

  @impl Oban.Worker
  def perform(_job) do
    {:ok, _count} = Recordings.recompute_popularity_scores(:dirty)
    :ok
  end
end
