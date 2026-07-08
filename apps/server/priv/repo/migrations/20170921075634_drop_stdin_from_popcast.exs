defmodule Popcorn.Repo.Migrations.DropStdinFromPopcast do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      remove :stdin_data
      remove :stdin_timing
    end
  end
end
