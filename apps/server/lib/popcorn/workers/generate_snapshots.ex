defmodule Popcorn.Workers.GenerateSnapshots do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Popcorn.Recordings
  alias Popcorn.Recordings.Query, as: RecordingQuery
  alias Popcorn.Workers.UpdateSnapshot

  @impl Oban.Worker
  def perform(_job) do
    popcasts =
      %RecordingQuery{scope: :system, filters: [:snapshotless]}
      |> Recordings.stream()

    Enum.each(popcasts, fn popcast ->
      Oban.insert!(UpdateSnapshot.new(%{popcast_id: popcast.id}))
    end)

    :ok
  end
end
