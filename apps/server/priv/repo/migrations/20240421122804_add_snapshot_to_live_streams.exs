defmodule Popcorn.Repo.Migrations.AddSnapshotToLiveStreams do
  use Ecto.Migration

  def change do
    alter table(:live_streams) do
      add :snapshot, :text
    end
  end
end
