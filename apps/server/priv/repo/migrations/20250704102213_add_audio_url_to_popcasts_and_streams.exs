defmodule Popcorn.Repo.Migrations.AddAudioUrlToPopcastsAndStreams do
  use Ecto.Migration

  def change do
    alter table(:popcasts) do
      add :audio_url, :string
    end

    alter table(:streams) do
      add :audio_url, :string
    end
  end
end
