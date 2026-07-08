defmodule PopcornWeb.FeatureCase do
  @moduledoc """
  This module defines the test case to be used by
  feature tests using Phoenix.Test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint PopcornWeb.Endpoint

      use PopcornWeb, :verified_routes

      import PhoenixTest

      import Phoenix.ConnTest,
        only: [
          init_test_session: 2,
          post: 2
        ]

      import Popcorn.Fixtures
      import Popcorn.Factory

      def log_in_user(conn, user) do
        init_test_session(conn, %{user_id: user.id})
      end

      defp link_from_email do
        assert_received {:email, %Swoosh.Email{} = email}
        [_, link] = Regex.run(~r{"(https?://[^"]+)"}, email.html_body)

        link
      end
    end
  end

  setup tags do
    Popcorn.DataCase.setup_sandbox(tags)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
