defmodule Popcorn.Workers.RecomputePopularityScores do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Popcorn.Recordings

  @impl Oban.Worker
  def perform(_job) do
    {:ok, _count} = Recordings.recompute_popularity_scores(:all)
    :ok
  end
end
