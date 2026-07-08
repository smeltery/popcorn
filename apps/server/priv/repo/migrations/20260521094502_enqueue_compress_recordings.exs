defmodule Popcorn.Repo.Migrations.EnqueueCompressRecordings do
  use Ecto.Migration

  def change do
    execute(fn ->
      %{}
      |> Oban.Job.new(worker: Popcorn.Workers.CompressRecordings)
      |> Popcorn.Repo.insert!()
    end, "")
  end
end
