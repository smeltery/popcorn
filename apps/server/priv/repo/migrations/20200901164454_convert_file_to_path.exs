defmodule Popcorn.Repo.Migrations.ConvertFileToPath do
  use Ecto.Migration

  def change do
    rename table(:popcasts), :file, to: :filename

    alter table(:popcasts) do
      add :path, :string
    end

    execute "UPDATE popcasts SET path=concat('popcast/file/', id, '/', filename) WHERE filename IS NOT NULL"
  end
end
