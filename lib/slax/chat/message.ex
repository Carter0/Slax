defmodule Slax.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: non_neg_integer(),
          body: String.t(),
          room_id: non_neg_integer(),
          user_id: non_neg_integer(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "messages" do
    field :body, :string
    field :room_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs, user_scope) do
    message
    |> cast(attrs, [:body])
    |> validate_required([:body])
    |> put_change(:user_id, user_scope.user.id)
  end
end
