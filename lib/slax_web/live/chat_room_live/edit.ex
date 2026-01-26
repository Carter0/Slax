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

        <.form
          for={@form}
          id="room-form"
          class="mt-10 space-y-8"
          phx-change="validate-room"
          phx-submit="save-room"
        >
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

  def handle_event("save-room", %{"room" => room_params}, socket) do
    case Chat.update_room(socket.assigns.room, room_params) do
      {:ok, room} ->
        {:noreply,
         socket
         |> put_flash(:info, "Room updated successfully")
         |> push_navigate(to: ~p"/rooms/#{room}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # "room" contains the inputs to the form so far.
  # It looks like this...
  # %{
  #  "room" => %{
  #    "name" => "Some name",
  #    "topic" => "Some topic"
  #  }
  # }
  # "room" is obtains from the inputs html room input. Inspect the element in the browser to see it.
  def handle_event("validate-room", %{"room" => room_params}, socket) do
    changeset =
      socket.assigns.room
      |> Chat.change_room(room_params)
      # The changeset needs to have a non-nil action in order for the form
      # to have an errors field populated.
      # This prevents error messages from showing prematurely
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
