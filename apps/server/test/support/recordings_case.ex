defmodule Popcorn.RecordingsCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Popcorn.DataCase, async: true

      import Popcorn.Factory
      import Popcorn.ZstdTestHelpers

      alias Popcorn.Recordings
      alias Popcorn.Recordings.{Popcast, PopcastStats, Query}
    end
  end
end
