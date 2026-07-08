defmodule Popcorn.Repo.Migrations.RenameVisibilityColumns do
  use Ecto.Migration

  def change do
    rename table(:users), :default_popcast_visibility, to: :default_recording_visibility
    execute "ALTER TYPE live_stream_visibility RENAME TO stream_visibility", "ALTER TYPE stream_visibility RENAME TO live_stream_visibility"
    execute "ALTER TYPE popcast_visibility RENAME TO recording_visibility", "ALTER TYPE recording_visibility RENAME TO popcast_visibility"
  end
end
