defmodule SlaxWeb.ChatRoomLive.Edit do
  use SlaxWeb, :live_view

  alias Slax.Chat

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto w-96 mt-12">
        <.header>
          {@page_title}
          <:actions>
            <.link
              class="font-normal text-xs text-blue-600 hover:text-blue-700"
              navigate={~p"/rooms/#{@room}"}
            >
              Back
            </.link>
          </:actions>
        </.header>

        <.form for={@form} id="room-form" class="mt-10 space-y-8">
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:topic]} type="text" label="Topic" />
          <div class="mt-2 flex items-center justify-between gap-6">
            <.button phx-disable-with="Saving..." class="btn btn-primary w-full">
              Save
            </.button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"id" => id} = _params, _session, socket) do
    room = Chat.get_room!(id)

    changeset = Chat.change_room(room)

    socket =
      socket
      |> assign(page_title: "Edit chat room", room: room)
      |> assign_form(changeset)

    {:ok, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
