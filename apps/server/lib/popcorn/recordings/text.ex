defmodule Popcorn.Recordings.Text do
  alias Popcorn.Recordings
  alias Popcorn.Recordings.Popcast
  alias Popcorn.Vt

  def text(%Popcast{term_cols: cols, term_rows: rows} = popcast) do
    {:ok, vt} = Vt.new(cols, rows, nil)

    popcast
    |> Recordings.event_stream()
    |> Enum.each(fn {_, code, data} ->
      case code do
        "o" ->
          Vt.feed(vt, data)

        "r" ->
          {cols, rows} = data
          Vt.resize(vt, cols, rows)

        _ ->
          :ok
      end
    end)

    Vt.text(vt)
  end
end
