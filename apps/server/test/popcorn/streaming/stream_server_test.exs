defmodule Popcorn.Streaming.StreamServerTest do
  use Popcorn.DataCase
  use Oban.Testing, repo: Popcorn.Repo

  import Popcorn.Factory

  alias Popcorn.FileStore
  alias Popcorn.Streaming
  alias Popcorn.Streaming.{StreamServer, StreamSupervisor}
  alias Popcorn.Workers.CreateStreamRecording

  describe "recording finalization" do
    test "stages the completed capture to FileStore and enqueues CreateStreamRecording" do
      user = insert(:user, stream_recording_enabled: true)
      stream = insert(:stream, user: user)

      {:ok, pid} = StreamSupervisor.start_child(stream.id)
      ref = Process.monitor(pid)

      :ok = StreamServer.claim(stream.id)

      :ok =
        StreamServer.reset(
          stream.id,
          %{time: 0, last_id: 1, term_size: {80, 24}, term_init: nil, term_theme: nil},
          "test/agent"
        )

      :ok = StreamServer.event(stream.id, :output, %{id: 2, time: 100_000, text: "hello"})
      :ok = StreamServer.stop(stream.id, :normal)

      assert_receive {:DOWN, ^ref, :process, ^pid, _}, 2_000

      stream_id = stream.id
      user_id = user.id

      assert_enqueued(
        worker: CreateStreamRecording,
        args: %{user_id: user_id, stream_id: stream_id, user_agent: "test/agent"}
      )

      [job] = all_enqueued(worker: CreateStreamRecording)
      file_store_path = job.args["file_store_path"]
      assert is_binary(file_store_path)

      assert file_store_path =~
               ~r"^tmp/stream-recordings/\d{4}/\d{2}/\d{2}/#{stream_id}-.+\.pop$"

      assert file_in_store?(file_store_path)
    end
  end

  describe "terminate/2" do
    test "terminates cleanly when the stream row was deleted while running" do
      stream = insert(:stream)

      {:ok, pid} = StreamSupervisor.start_child(stream.id)
      ref = Process.monitor(pid)

      Streaming.delete_stream(stream)

      assert :ok = StreamServer.stop(stream.id, :normal)
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 2_000
    end
  end

  defp file_in_store?(path) do
    "file://" <> abs_path = FileStore.uri(path)
    File.exists?(abs_path)
  end
end
