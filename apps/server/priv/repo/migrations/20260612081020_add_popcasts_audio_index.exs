defmodule Popcorn.Repo.Migrations.AddPopcastsAudioIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:popcasts, ["(1)"],
             where: "audio_url IS NOT NULL",
             name: "popcasts_audio_index",
             concurrently: true
           )
  end
end
