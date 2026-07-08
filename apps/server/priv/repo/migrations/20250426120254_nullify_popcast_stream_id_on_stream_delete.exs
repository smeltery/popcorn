defmodule Popcorn.Repo.Migrations.NullifyPopcastStreamIdOnStreamDelete do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      modify :stream_id, references(:streams, on_delete: :nilify_all),
        from: references(:streams, on_delete: :nothing)
    end
  end
end
