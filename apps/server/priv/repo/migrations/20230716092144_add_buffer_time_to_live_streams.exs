defmodule Popcorn.Repo.Migrations.AddBufferTimeToLiveStreams do
  use Ecto.Migration

  def change do
    alter table(:live_streams) do
      add :buffer_time, :float
    end
  end
end
