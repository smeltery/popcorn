defmodule Popcorn.Repo.Migrations.MakeAsciiastUserIdNonNull do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      modify :user_id, references(:users), null: false
    end

    drop constraint(:popcasts, "popcasts_user_id_fk")
  end
end
