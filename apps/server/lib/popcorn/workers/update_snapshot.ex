defmodule Popcorn.Workers.UpdateSnapshot do
  use Oban.Worker,
    unique: [
      period: :infinity,
      states: [:available, :retryable]
    ]

  alias Popcorn.Recordings
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"popcast_id" => id}}) do
    Logger.info("updating snapshot for recording #{id}...")

    with {:ok, popcast} <- Recordings.fetch_popcast(id),
         {:ok, _} <- Recordings.update_snapshot(popcast) do
      Logger.info("snapshot for recording #{id} updated")

      :ok
    else
      {:error, :not_found} -> :discard
      {:error, _} = result -> result
      result -> {:error, result}
    end
  end
end
