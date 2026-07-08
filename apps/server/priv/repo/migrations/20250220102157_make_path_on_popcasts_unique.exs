defmodule Popcorn.Repo.Migrations.MakePathOnPopcastsUnique do
  use Ecto.Migration

  def change do
    create unique_index(:popcasts, [:path])
  end
end
