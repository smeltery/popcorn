defmodule Popcorn.Repo.Migrations.AddIdleTimeLimitToPopcast do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :idle_time_limit, :float
    end
  end
end
