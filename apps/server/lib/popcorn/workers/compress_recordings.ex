defmodule Popcorn.Workers.CompressRecordings do
  use Oban.Worker,
    queue: :maintenance,
    unique: [period: :infinity, states: :incomplete]

  alias Popcorn.Recordings
  alias Popcorn.Workers.CompressRecording

  @impl Oban.Worker
  def perform(_job) do
    Enum.each(Recordings.uncompressed_popcast_ids_stream(), fn id ->
      Oban.insert!(CompressRecording.new(%{popcast_id: id}))
    end)

    :ok
  end
end
