defmodule Popcorn.Recordings.Paths do
  use Popcorn.Config

  @default_popcast_tpl "recordings/{username}/{year}/{month}/{day}/{id}.{ext}"

  def path(popcast) do
    :recording
    |> config(@default_popcast_tpl)
    |> path(popcast)
  end

  defp path(tpl, popcast) do
    time = popcast.inserted_at

    vars = %{
      "{username}" => popcast.user.username || "_user#{popcast.user_id}",
      "{id}" => to_string(popcast.id),
      "{year}" => to_string(time.year),
      "{month}" => String.pad_leading(to_string(time.month), 2, "0"),
      "{day}" => String.pad_leading(to_string(time.day), 2, "0"),
      "{shard}" => shard(popcast.id),
      "{ext}" => ext(popcast.version, popcast.compressed)
    }

    tpl
    |> String.replace(Map.keys(vars), &Map.get(vars, &1))
    |> String.replace(~r/\{env:(\w+(\?[^}]*)?)\}/U, &resolve_env_var(&1, popcast.env))
  end

  defp shard(id) do
    <<a::binary-size(2), b::binary-size(2)>> =
      id
      |> Integer.to_string(10)
      |> String.pad_leading(4, "0")
      |> String.reverse()
      |> String.slice(0, 4)

    "#{a}/#{b}"
  end

  defp ext(1, compressed), do: if(compressed, do: "json.zst", else: "json")
  defp ext(_, compressed), do: if(compressed, do: "pop.zst", else: "pop")

  defp resolve_env_var(match, env) do
    env = env || %{}
    rest = String.slice(match, 5..-2//1)

    case String.split(rest, "?", parts: 2) do
      [name, default] ->
        Map.get(env, name, default)

      [name] ->
        Map.get(env, name, "")
    end
  end
end
