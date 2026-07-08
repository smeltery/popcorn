defmodule Popcorn.Repo.Migrations.RenamePopcastsIndexes do
  use Ecto.Migration

  def change do
    execute "ALTER INDEX index_popcasts_on_created_at RENAME TO popcasts_created_at_index"
    execute "ALTER INDEX index_popcasts_on_featured RENAME TO popcasts_featured_index"
    execute "ALTER INDEX index_popcasts_on_secret_token RENAME TO popcasts_secret_token_index"
    execute "ALTER INDEX index_popcasts_on_user_id RENAME TO popcasts_user_id_index"
  end
end
