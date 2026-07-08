defmodule Popcorn.Repo.Migrations.AddPopcastsDurationIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:popcasts, [:duration], concurrently: true)
  end
end
