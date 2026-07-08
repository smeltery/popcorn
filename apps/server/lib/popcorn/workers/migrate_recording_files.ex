defmodule Popcorn.Workers.MigrateRecordingFiles do
  use Oban.Worker,
    unique: [
      period: :infinity,
      states: [:available, :retryable]
    ]

  require Logger
  alias Popcorn.Recordings
  alias Popcorn.Recordings.Query, as: RecordingQuery

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"popcast_id" => id}}) do
    Logger.info("migrating file for recording #{id}...")
    Recordings.migrate_file(id)
    Logger.info("recording #{id} file migrated")

    :ok
  end

  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    popcasts =
      %RecordingQuery{scope: :system, filters: [{:user, user_id}]}
      |> Recordings.stream()
      |> Recordings.migratable()

    Enum.each(popcasts, fn popcast ->
      Oban.insert!(__MODULE__.new(%{popcast_id: popcast.id}))
    end)

    :ok
  end

  def perform(_job) do
    popcasts =
      %RecordingQuery{scope: :system}
      |> Recordings.stream()
      |> Recordings.migratable()

    Enum.each(popcasts, fn popcast ->
      Oban.insert!(__MODULE__.new(%{popcast_id: popcast.id}))
    end)

    :ok
  end
end
