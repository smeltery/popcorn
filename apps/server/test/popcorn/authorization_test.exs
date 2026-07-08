defmodule Popcorn.AuthorizationTest do
  use ExUnit.Case, async: true
  alias Popcorn.Accounts.User
  alias Popcorn.Authorization
  alias Popcorn.Recordings.Popcast
  alias Popcorn.Streaming.Stream

  describe "can?/3 for Popcast" do
    test "owner can read its own private popcast" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 1, visibility: :private}

      assert Authorization.can?(user, :show, popcast)
    end

    test "owner can read its own unlisted popcast via id" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 1, visibility: :unlisted}

      assert Authorization.can?(user, :show, popcast)
    end

    test "owner can read its own unlisted popcast via secret token" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 1, visibility: :unlisted}

      assert Authorization.can?(user, :show, popcast)
    end

    test "any user can read an unlisted popcast given it knows the secret token" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 2, visibility: :unlisted}

      assert Authorization.can?(user, :show, popcast)
    end

    test "any user can read a public popcast" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 2, visibility: :public}

      assert Authorization.can?(user, :show, popcast)
    end

    test "a guest can read a public popcast" do
      popcast = %Popcast{user_id: 2, visibility: :public}

      assert Authorization.can?(nil, :show, popcast)
    end

    test "a guest cannot read a private popcast" do
      popcast = %Popcast{user_id: 1, visibility: :private}

      refute Authorization.can?(nil, :show, popcast)
    end

    test "a guest can read an unlisted popcast" do
      popcast = %Popcast{user_id: 1, visibility: :unlisted}

      assert Authorization.can?(nil, :show, popcast)
    end

    test "a guest can read an unlisted popcast given it knows the secret token" do
      popcast = %Popcast{user_id: 1, visibility: :unlisted}

      assert Authorization.can?(nil, :show, popcast)
    end

    test "non-owner cannot read a private popcast" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 2, visibility: :private}

      refute Authorization.can?(user, :show, popcast)
    end

    test "non-owner can read an unlisted popcast" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 2, visibility: :unlisted}

      assert Authorization.can?(user, :show, popcast)
    end

    test "admin can read a private popcast" do
      admin = %User{id: 1, is_admin: true}
      popcast = %Popcast{user_id: 2, visibility: :private}

      assert Authorization.can?(admin, :show, popcast)
    end

    test "admin can read an unlisted popcast" do
      admin = %User{id: 1, is_admin: true}
      popcast = %Popcast{user_id: 2, visibility: :unlisted}

      assert Authorization.can?(admin, :show, popcast)
    end

    test "owner can update their own popcast" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :update, popcast)
    end

    test "non-owner cannot update someone else's popcast" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :update, popcast)
    end

    test "admin can update any popcast" do
      admin = %User{id: 1, is_admin: true}
      popcast = %Popcast{user_id: 2, visibility: :public}

      assert Authorization.can?(admin, :update, popcast)
    end

    test "guest cannot update an popcast" do
      popcast = %Popcast{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :update, popcast)
    end

    test "owner can delete their own popcast" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :delete, popcast)
    end

    test "non-owner cannot delete someone else's popcast" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :delete, popcast)
    end

    test "admin can delete any popcast" do
      admin = %User{id: 1, is_admin: true}
      popcast = %Popcast{user_id: 2, visibility: :public}

      assert Authorization.can?(admin, :delete, popcast)
    end

    test "guest cannot delete an popcast" do
      popcast = %Popcast{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :delete, popcast)
    end
  end

  describe "can?/3 for Stream" do
    test "any user can see a public stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :public}

      assert Authorization.can?(user, :show, stream)
    end

    test "any user can see an unlisted stream given it knows the public token" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :unlisted}

      assert Authorization.can?(user, :show, stream)
    end

    test "a guest can see a public stream" do
      stream = %Stream{user_id: 1, visibility: :public}

      assert Authorization.can?(nil, :show, stream)
    end

    test "a guest cannot see a private stream" do
      stream = %Stream{user_id: 1, visibility: :private}

      refute Authorization.can?(nil, :show, stream)
    end

    test "a guest can see an unlisted stream" do
      stream = %Stream{user_id: 1, visibility: :unlisted}

      assert Authorization.can?(nil, :show, stream)
    end

    test "a guest can see an unlisted stream given it knows the public token" do
      stream = %Stream{user_id: 1, visibility: :unlisted}

      assert Authorization.can?(nil, :show, stream)
    end

    test "owner can see their own private stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 1, visibility: :private}

      assert Authorization.can?(user, :show, stream)
    end

    test "owner can see their own unlisted stream via id" do
      user = %User{id: 1}
      stream = %Stream{user_id: 1, visibility: :unlisted}

      assert Authorization.can?(user, :show, stream)
    end

    test "owner can see their own unlisted stream via public token" do
      user = %User{id: 1}
      stream = %Stream{user_id: 1, visibility: :unlisted}

      assert Authorization.can?(user, :show, stream)
    end

    test "non-owner cannot see a private stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :private}

      refute Authorization.can?(user, :show, stream)
    end

    test "non-owner can see an unlisted stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :unlisted}

      assert Authorization.can?(user, :show, stream)
    end

    test "admin can see a private stream" do
      admin = %User{id: 1, is_admin: true}
      stream = %Stream{user_id: 2, visibility: :private}

      assert Authorization.can?(admin, :show, stream)
    end

    test "admin can see an unlisted stream via id" do
      admin = %User{id: 1, is_admin: true}
      stream = %Stream{user_id: 2, visibility: :unlisted}

      assert Authorization.can?(admin, :show, stream)
    end

    test "owner can update their own stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :update, stream)
    end

    test "non-owner cannot update someone else's stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :update, stream)
    end

    test "admin can update any stream" do
      admin = %User{id: 1, is_admin: true}
      stream = %Stream{user_id: 2, visibility: :public}

      assert Authorization.can?(admin, :update, stream)
    end

    test "guest cannot update a stream" do
      stream = %Stream{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :update, stream)
    end

    test "owner can delete their own stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :delete, stream)
    end

    test "non-owner cannot delete someone else's stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :delete, stream)
    end

    test "admin can delete any stream" do
      admin = %User{id: 1, is_admin: true}
      stream = %Stream{user_id: 2, visibility: :public}

      assert Authorization.can?(admin, :delete, stream)
    end

    test "guest cannot delete a stream" do
      stream = %Stream{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :delete, stream)
    end
  end

  describe "can?/3 for User" do
    test "user can update their own profile" do
      user = %User{id: 1}
      target_user = %User{id: 1}

      assert Authorization.can?(user, :update, target_user)
    end

    test "user cannot update someone else's profile" do
      user = %User{id: 1}
      target_user = %User{id: 2}

      refute Authorization.can?(user, :update, target_user)
    end

    test "admin can update any user" do
      admin = %User{id: 1, is_admin: true}
      target_user = %User{id: 2}

      assert Authorization.can?(admin, :update, target_user)
    end

    test "guest cannot update a user" do
      target_user = %User{id: 1}

      refute Authorization.can?(nil, :update, target_user)
    end
  end

  describe "deny-by-default" do
    test "unknown action is denied for non-owner" do
      user = %User{id: 1}
      popcast = %Popcast{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :unknown_action, popcast)
    end

    test "unknown action is denied for guest" do
      popcast = %Popcast{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :unknown_action, popcast)
    end

    test "unknown resource type is denied" do
      user = %User{id: 1}

      refute Authorization.can?(user, :show, %{some: "map"})
    end
  end
end
