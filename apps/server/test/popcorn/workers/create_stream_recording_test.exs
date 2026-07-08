defmodule Popcorn.Workers.CreateStreamRecordingTest do
  use Popcorn.DataCase, async: true
  use Oban.Testing, repo: Popcorn.Repo

  import Popcorn.Factory
  import Ecto.Query

  alias Popcorn.FileStore
  alias Popcorn.Recordings.Popcast
  alias Popcorn.Workers.CreateStreamRecording

  @cast_fixture "test/fixtures/3/full.pop"
  @empty_cast_fixture "test/fixtures/3/no-events.pop"

  describe "perform/1" do
    test "creates a recording from a staged capture and deletes the staged file" do
      user = insert(:user)
      stream = insert(:stream, user: user)
      staging_path = stage_cast(stream.id)

      args = %{
        "user_id" => user.id,
        "stream_id" => stream.id,
        "file_store_path" => staging_path,
        "user_agent" => "test/agent",
        "term_bold_is_bright" => true,
        "term_adaptive_palette" => false,
        "keystroke_overlay" => true,
        "term_cursor_mode" => "hidden"
      }

      assert :ok = perform_job(CreateStreamRecording, args)

      assert [
               %Popcast{
                 stream_id: stream_id,
                 user_agent: "test/agent",
                 term_bold_is_bright: true,
                 term_adaptive_palette: false,
                 keystroke_overlay: true,
                 term_cursor_mode: "hidden",
                 filename: "stream.pop"
               } = popcast
             ] = popcasts_for(user)

      assert stream_id == stream.id
      refute popcast.archived_at
      refute file_in_store?(staging_path)
    end

    test "retries with stream_id: nil when stream is missing" do
      user = insert(:user)
      missing_stream_id = 999_999_999
      staging_path = stage_cast(missing_stream_id)

      args = %{
        "user_id" => user.id,
        "stream_id" => missing_stream_id,
        "file_store_path" => staging_path,
        "user_agent" => "test/agent",
        "term_bold_is_bright" => false,
        "term_adaptive_palette" => false,
        "keystroke_overlay" => false,
        "term_cursor_mode" => "blinking"
      }

      assert :ok = perform_job(CreateStreamRecording, args)

      assert [%Popcast{stream_id: nil}] = popcasts_for(user)
      refute file_in_store?(staging_path)
    end

    test "discards when user no longer exists and keeps the staged file" do
      stream = insert(:stream)
      staging_path = stage_cast(stream.id)

      args = %{
        "user_id" => 999_999_999,
        "stream_id" => stream.id,
        "file_store_path" => staging_path,
        "user_agent" => nil,
        "term_bold_is_bright" => false,
        "term_adaptive_palette" => false
      }

      assert :discard = perform_job(CreateStreamRecording, args)
      assert file_in_store?(staging_path)
    end

    test "discards an empty staged capture and deletes the staged file" do
      user = insert(:user)
      stream = insert(:stream, user: user)
      staging_path = stage_cast(stream.id, @empty_cast_fixture)

      args = %{
        "user_id" => user.id,
        "stream_id" => stream.id,
        "file_store_path" => staging_path,
        "user_agent" => "test/agent",
        "term_bold_is_bright" => false,
        "term_adaptive_palette" => false,
        "keystroke_overlay" => false,
        "term_cursor_mode" => "blinking"
      }

      assert :discard = perform_job(CreateStreamRecording, args)
      assert [] = popcasts_for(user)
      refute file_in_store?(staging_path)
    end
  end

  defp popcasts_for(user) do
    Repo.all(from a in Popcast, where: a.user_id == ^user.id)
  end

  defp stage_cast(stream_id, fixture \\ @cast_fixture) do
    path = "tmp/stream-recordings/test/#{stream_id}-#{System.unique_integer([:positive])}.pop"
    :ok = FileStore.put_file(path, fixture, "application/x-popcast")
    path
  end

  defp file_in_store?(path) do
    "file://" <> abs_path = FileStore.uri(path)
    File.exists?(abs_path)
  end
end
