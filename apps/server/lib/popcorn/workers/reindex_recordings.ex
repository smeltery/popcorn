defmodule Popcorn.Workers.ReindexRecordings do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Popcorn.Recordings
  alias Popcorn.Recordings.Query, as: RecordingQuery
  alias Popcorn.Workers.UpdateFtsContent

  @impl Oban.Worker
  def perform(_job) do
    popcasts = Recordings.stream(%RecordingQuery{scope: :system})

    Enum.each(popcasts, fn popcast ->
      Oban.insert!(UpdateFtsContent.new(%{popcast_id: popcast.id}))
    end)

    :ok
  end
end
