defmodule Popcorn.Repo.Migrations.RenameStreamParserToProtocol do
  use Ecto.Migration

  def change do
    rename table(:live_streams), :parser, to: :protocol

    execute "UPDATE live_streams SET protocol='v0.alis' WHERE protocol='alis'"
    execute "UPDATE live_streams SET protocol='v2.popcast' WHERE protocol='json'"
  end
end
