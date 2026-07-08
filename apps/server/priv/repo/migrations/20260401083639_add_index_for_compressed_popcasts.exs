defmodule Popcorn.Repo.Migrations.AddIndexForCompressedPopcasts do
  use Ecto.Migration

  def change do
    create index(:popcasts, [:compressed])
  end
end
