defmodule PopcornWeb.Features.StaticPagesTest do
  use PopcornWeb.FeatureCase, async: true

  test "about page", %{conn: conn} do
    conn
    |> visit("/about")
    |> assert_has("h2")
  end
end
