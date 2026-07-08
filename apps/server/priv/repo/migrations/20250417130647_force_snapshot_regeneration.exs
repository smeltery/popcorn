defmodule Popcorn.Repo.Migrations.ForceSnapshotRegeneration do
  use Ecto.Migration

  def up do
    execute "UPDATE popcasts SET snapshot = NULL"

    %{}
    |> Oban.Job.new(worker: Popcorn.Workers.GenerateSnapshots)
    |> Popcorn.Repo.insert!()
  end

  def down, do: :ok
end
