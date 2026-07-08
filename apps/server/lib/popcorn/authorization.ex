defmodule Popcorn.Authorization do
  alias Popcorn.Accounts.User
  alias Popcorn.Recordings.Popcast
  alias Popcorn.Streaming.Stream

  defmodule Policy do
    # for popcasts

    def can?(%User{id: uid}, :show, %Popcast{user_id: uid}), do: true
    def can?(%User{id: uid}, :update, %Popcast{user_id: uid}), do: true
    def can?(%User{id: uid}, :delete, %Popcast{user_id: uid}), do: true
    def can?(_user, :show, %Popcast{visibility: :unlisted}), do: true
    def can?(_user, :show, %Popcast{visibility: :public}), do: true

    # for streams

    def can?(%User{id: uid}, :show, %Stream{user_id: uid}), do: true
    def can?(%User{id: uid}, :update, %Stream{user_id: uid}), do: true
    def can?(%User{id: uid}, :delete, %Stream{user_id: uid}), do: true
    def can?(_user, :show, %Stream{visibility: :unlisted}), do: true
    def can?(_user, :show, %Stream{visibility: :public}), do: true

    # for user

    def can?(%User{id: uid}, :update, %User{id: uid}), do: true

    # as admin

    def can?(%User{is_admin: true}, :show, %Popcast{}), do: true
    def can?(%User{is_admin: true}, :update, %Popcast{}), do: true
    def can?(%User{is_admin: true}, :delete, %Popcast{}), do: true
    def can?(%User{is_admin: true}, :show, %Stream{}), do: true
    def can?(%User{is_admin: true}, :update, %Stream{}), do: true
    def can?(%User{is_admin: true}, :delete, %Stream{}), do: true
    def can?(%User{is_admin: true}, :update, %User{}), do: true

    # deny everything else

    def can?(_user, _action, _thing), do: false
  end

  def can?(user, action, resource), do: Policy.can?(user, action, resource)
end
