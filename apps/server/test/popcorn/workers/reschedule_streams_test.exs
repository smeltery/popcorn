defmodule Popcorn.Workers.RescheduleStreamsTest do
  use Popcorn.DataCase, async: true
  import Popcorn.Factory
  alias Popcorn.Workers.RescheduleStreams

  describe "perform/1" do
    test "succeeds" do
      insert(:stream, schedule: nil, next_start_at: nil)
      insert(:stream, schedule: "* * * * * *", next_start_at: ~U[2000-01-01T00:00:00Z])
      job = RescheduleStreams.new(%{})

      assert RescheduleStreams.perform(job) == :ok
    end
  end
end
