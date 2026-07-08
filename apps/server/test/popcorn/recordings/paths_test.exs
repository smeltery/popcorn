defmodule Popcorn.Recordings.PathsTest do
  use Popcorn.DataCase, async: true
  import Popcorn.Factory
  alias Popcorn.AppEnv
  alias Popcorn.Recordings.Paths

  describe "path/1" do
    test "returns path with json ext for popcast v1" do
      now = Timex.now()
      date = Timex.format!(now, "{YYYY}/{0M}/{0D}")
      popcast = build_popcast(version: 1, inserted_at: now)

      path = Paths.path(popcast)

      assert path == "recordings/foo/#{date}/123.json"
    end

    test "returns path with json.zst ext for compressed popcast v1" do
      now = Timex.now()
      date = Timex.format!(now, "{YYYY}/{0M}/{0D}")
      popcast = build_popcast(version: 1, compressed: true, inserted_at: now)

      path = Paths.path(popcast)

      assert path == "recordings/foo/#{date}/123.json.zst"
    end

    test "returns path with cast ext for popcast v2" do
      now = Timex.now()
      date = Timex.format!(now, "{YYYY}/{0M}/{0D}")
      popcast = build_popcast(version: 2, inserted_at: now)

      path = Paths.path(popcast)

      assert path == "recordings/foo/#{date}/123.pop"
    end

    test "returns path with cast.zst ext for compressed popcast v2" do
      now = Timex.now()
      date = Timex.format!(now, "{YYYY}/{0M}/{0D}")
      popcast = build_popcast(version: 2, compressed: true, inserted_at: now)

      path = Paths.path(popcast)

      assert path == "recordings/foo/#{date}/123.pop.zst"
    end

    test "uses last 4 digits (reversed) for {shard} token - short id" do
      AppEnv.put(Paths, recording: "popcasts/{shard}/{id}.{ext}")
      popcast = build_popcast(id: 1)

      path = Paths.path(popcast)

      assert path == "popcasts/10/00/1.pop"
    end

    test "uses last 4 digits (reversed) for {shard} token - long id" do
      AppEnv.put(Paths, recording: "popcasts/{shard}/{id}.{ext}")
      popcast = build_popcast(id: 12345)

      path = Paths.path(popcast)

      assert path == "popcasts/54/32/12345.pop"
    end

    test "interpolates env vars" do
      AppEnv.put(Paths,
        recording: "recordings/{env:A_YES}-{env:A_NOPE?nope}-{env:NADA?}/{id}.{ext}"
      )

      popcast = build_popcast(env: %{"A_YES" => "yes"})

      path = Paths.path(popcast)

      assert path == "recordings/yes-nope-/123.pop"
    end
  end

  defp build_popcast(overrides) do
    attrs =
      Keyword.merge(
        [id: 123, version: 2, inserted_at: Timex.now(), user: build(:user, username: "foo")],
        overrides
      )

    build(:popcast, attrs)
  end
end
