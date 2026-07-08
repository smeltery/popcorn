defmodule PopcornWeb.AuthorizationTest do
  use ExUnit.Case, async: true
  alias Popcorn.Accounts.User
  alias Popcorn.Recordings.Popcast
  alias Popcorn.Streaming.Stream
  alias PopcornWeb.Authorization

  describe "can?/3 :edit action" do
    test "delegates to update for popcast owner" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :edit, popcast)
    end

    test "delegates to update for popcast non-owner" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :edit, popcast)
    end

    test "delegates to update for guest on popcast" do
      popcast = %Popcast{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :edit, popcast)
    end

    test "delegates to update for stream owner" do
      user = %User{id: 1}
      stream = %Stream{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :edit, stream)
    end

    test "delegates to update for stream non-owner" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :edit, stream)
    end

    test "delegates to update for guest on stream" do
      stream = %Stream{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :edit, stream)
    end
  end

  describe "can?/3 :iframe action" do
    test "delegates to show for public popcast" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 2, visibility: :public}

      assert Authorization.can?(user, :iframe, popcast)
    end

    test "delegates to show for guest on private popcast" do
      popcast = %Popcast{user_id: 1, visibility: :private}

      refute Authorization.can?(nil, :iframe, popcast)
    end

    test "delegates to show for guest on unlisted popcast" do
      popcast = %Popcast{user_id: 1, visibility: :unlisted}

      assert Authorization.can?(nil, :iframe, popcast)
    end

    test "delegates to show for guest on public popcast" do
      popcast = %Popcast{user_id: 1, visibility: :public}

      assert Authorization.can?(nil, :iframe, popcast)
    end

    test "delegates to show for public stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :public}

      assert Authorization.can?(user, :iframe, stream)
    end

    test "delegates to show for guest on private stream" do
      stream = %Stream{user_id: 1, visibility: :private}

      refute Authorization.can?(nil, :iframe, stream)
    end

    test "delegates to show for guest on unlisted stream" do
      stream = %Stream{user_id: 1, visibility: :unlisted}

      assert Authorization.can?(nil, :iframe, stream)
    end

    test "delegates to show for guest on public stream" do
      stream = %Stream{user_id: 1, visibility: :public}

      assert Authorization.can?(nil, :iframe, stream)
    end
  end
end
