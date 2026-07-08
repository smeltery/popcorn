defmodule PopcornAdmin.ConnCase do
  @moduledoc """
  Test case for PopcornAdmin (admin endpoint) controller and live tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint PopcornAdmin.Endpoint

      use PopcornAdmin, :verified_routes

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Plug.Conn
      import Phoenix.ConnTest
      import Popcorn.Factory
      import Popcorn.Fixtures

      defp flash(conn, key) do
        Phoenix.Flash.get(conn.assigns.flash, key)
      end
    end
  end

  setup tags do
    Popcorn.DataCase.setup_sandbox(tags)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
