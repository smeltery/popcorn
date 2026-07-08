defmodule Popcorn.Workers.CompressRecording do
  use Oban.Worker,
    queue: :maintenance,
    unique: [period: :infinity, states: :incomplete]

  alias Popcorn.Recordings
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"popcast_id" => id}}) do
    Logger.info("compressing recording #{id}...")

    with {:ok, popcast} <- Recordings.fetch_popcast(id),
         {:ok, _popcast} <- Recordings.compress_popcast(popcast) do
      Logger.info("recording #{id} compressed")
      :ok
    else
      {:error, :not_found} -> :discard
      {:error, _} = result -> result
      result -> {:error, result}
    end
  end
end
