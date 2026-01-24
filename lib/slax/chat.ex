defmodule Slax.Chat do
  alias Slax.Chat.Room
  alias Slax.Repo

  import Ecto.Query

  @spec list_rooms() :: [Room.t()]
  def list_rooms do
    Room
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

  @spec create_room(map()) :: Room.t()
  def create_room(attrs) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_room(Room.t(), map()) :: Room.t()
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end
end
