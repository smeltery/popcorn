defmodule Popcorn.Workers.CompressRecordingsTest do
  use Popcorn.DataCase, async: true
  use Oban.Testing, repo: Popcorn.Repo

  import Popcorn.Factory

  alias Popcorn.Workers.{CompressRecording, CompressRecordings}

  describe "perform/1" do
    test "enqueues uncompressed popcasts including archived ones" do
      active = insert(:popcast_v2, compressed: false)
      archived = insert(:popcast_v2, compressed: false, archived_at: ~U[2024-01-01T00:00:00Z])
      compressed = insert(:popcast_v2, compressed: true)

      assert :ok = CompressRecordings.perform(CompressRecordings.new(%{}))

      assert_enqueued(worker: CompressRecording, args: %{popcast_id: active.id})
      assert_enqueued(worker: CompressRecording, args: %{popcast_id: archived.id})
      refute_enqueued(worker: CompressRecording, args: %{popcast_id: compressed.id})
    end
  end
end
