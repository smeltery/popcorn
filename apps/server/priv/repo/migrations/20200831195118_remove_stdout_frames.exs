defmodule Popcorn.Repo.Migrations.RemoveStdoutFrames do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      remove :stdout_frames
    end
  end
end
