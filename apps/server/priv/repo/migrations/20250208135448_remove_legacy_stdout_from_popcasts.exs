defmodule Popcorn.Repo.Migrations.RemoveLegacyStdoutFromPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      remove :stdout_data
      remove :stdout_timing
    end
  end
end
