defmodule Slax.Chat do
  alias Slax.Chat.RoomMembership
  alias Slax.Accounts.{Scope, User}
  alias Slax.Chat.{Room, RoomMembership, Message}
  alias Slax.Repo

  import Ecto.Query

  @pubsub Slax.PubSub

  @spec joined?(Room.t(), User.t()) :: boolean()
  def joined?(%Room{} = room, %User{} = user) do
    RoomMembership
    |> where([rm], rm.room_id == ^room.id and rm.user_id == ^user.id)
    |> Repo.exists?()
  end

  @spec join_room!(Room.t(), User.t()) :: RoomMembership.t()
  def join_room!(room, user) do
    Repo.insert!(%RoomMembership{room: room, user: user})
  end

  @spec list_rooms() :: [Room.t()]
  def list_rooms do
    Room
    |> order_by(asc: :name)
    |> Repo.all()
  end

  @spec list_joined_rooms(User.t()) :: [Room.t()]
  def list_joined_rooms(%User{} = user) do
    user
    |> Repo.preload(:rooms)
    |> Map.fetch!(:rooms)
    |> Enum.sort_by(& &1.name)
  end

  @spec list_rooms_with_joined(User.t()) :: [Room.t()]
  def list_rooms_with_joined(%User{} = user) do
    Room
    |> join(:left, [r], rm in RoomMembership, on: rm.room_id == r.id and rm.user_id == ^user.id)
    |> select([r, rm], {r, not is_nil(rm.id)})
    |> order_by(asc: :name)
    |> Repo.all()
  end

  @spec get_room!(integer()) :: Room.t()
  def get_room!(id) do
    Repo.get!(Room, id)
  end

  @spec change_room(Room.t(), map) :: Ecto.Changeset.t()
  def change_room(room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  @spec create_room(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_room(attrs) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_room(Room.t(), map()) :: {:ok, Room.t()} | {:error, Ecto.Changeset.t()}
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @spec list_messages_in_room(Room.t()) :: [Message.t()]
  def list_messages_in_room(%Room{id: room_id}) do
    Message
    |> where([m], m.room_id == ^room_id)
    |> order_by([m], asc: :inserted_at, asc: :id)
    |> preload(:user)
    |> Repo.all()
  end

  @spec change_message(Message.t(), map(), Scope.t()) :: Ecto.Changeset.t()
  def change_message(message, attrs \\ %{}, scope) do
    Message.changeset(message, attrs, scope)
  end

  ####################### PUBSUB ###########################

  # Pubsub stands for the (publish-subscribe) pattern.

  # I am using pubsub because I want users to see updates on slax pages
  # without having to reload the page. By using the BEAM and processes specifically,
  # I can pass messages to process to update the page in real time.

  # Pubsub is implemented in Phoenix for us and is easy to use in elixir with
  # elixir's built in concurrency features.

  @spec create_message(Room.t(), map(), Scope.t()) ::
          {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def create_message(room, attrs, scope) do
    with {:ok, message} <-
           %Message{room: room}
           |> Message.changeset(attrs, scope)
           |> Repo.insert() do
      message = Repo.preload(message, :user)
      Phoenix.PubSub.broadcast!(@pubsub, topic(room.id), {:new_message, message})
      {:ok, message}
    end
  end

  @spec delete_message_by_id(integer(), Scope.t()) :: :ok
  def delete_message_by_id(id, %Scope{user: user}) do
    message = Repo.get_by!(Message, id: id, user_id: user.id)

    Repo.delete(message)

    Phoenix.PubSub.broadcast!(@pubsub, topic(message.room_id), {:message_deleted, message})
  end

  @spec subscribe_to_room(Room.t()) :: :ok | {:error, term()}
  def subscribe_to_room(room) do
    Phoenix.PubSub.subscribe(@pubsub, topic(room.id))
  end

  @spec unsubscribe_from_room(Room.t()) :: :ok
  def unsubscribe_from_room(room) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(room.id))
  end

  defp topic(room_id), do: "chat_room:#{room_id}"
end
