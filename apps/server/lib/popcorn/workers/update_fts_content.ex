defmodule Popcorn.Workers.UpdateFtsContent do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Popcorn.Recordings
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"popcast_id" => id}}) do
    Logger.info("generating FTS content for recording #{id}...")

    with {:ok, popcast} <- Recordings.fetch_popcast(id),
         :ok <- Recordings.update_fts_content(popcast) do
      Logger.info("FTS content for recording #{id} generated")

      :ok
    else
      {:error, :not_found} -> :discard
      {:error, _} = result -> result
      result -> {:error, result}
    end
  end
end
