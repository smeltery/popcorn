defmodule Popcorn.Repo.Migrations.AddEnvToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :env, :map
    end

    execute("CREATE INDEX popcasts_env_index ON popcasts USING GIN(env)", "DROP INDEX popcasts_env_index")
  end
end
