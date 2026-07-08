defmodule Popcorn.Repo.Migrations.AddSizeToPopcasts do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :uncompressed_size, :integer
      add :compressed_size, :integer
    end
  end
end
