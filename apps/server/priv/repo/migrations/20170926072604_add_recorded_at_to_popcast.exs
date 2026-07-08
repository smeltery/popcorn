defmodule Popcorn.Repo.Migrations.AddRecordedAtToPopcast do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :recorded_at, :naive_datetime
    end
  end
end
