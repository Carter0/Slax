defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

  alias Slax.{Accounts, Chat}
  alias Slax.Accounts.User
  alias Slax.Chat.{Room, Message}
  alias SlaxWeb.OnlineUsers

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-col shrink-0 w-64 bg-slate-100">
        <div class="flex justify-between items-center shrink-0 h-16 border-b border-slate-300 px-4">
          <div class="flex flex-col gap-1.5">
            <h1 class="text-lg font-bold text-gray-800">
              Slax
            </h1>
          </div>
        </div>
        <div class="mt-4 overflow-auto">
          <div class="flex items-center h-8 px-3">
            <span class="ml-2 leading-none font-medium text-sm">
              Rooms
            </span>
          </div>
          <div id="rooms-list">
            <.room_link :for={room <- @rooms} room={room} active={room.id == @room.id} />
          </div>
          <div class="mt-4">
            <div class="flex items-center h-8 px-3">
              <div class="flex items-center grow">
                <span class="ml-2 leading-none font-medium text-sm">
                  Users
                </span>
              </div>
            </div>
            <div id="users-list">
              <.user
                :for={user <- @users}
                user={user}
                online={OnlineUsers.online?(@online_users, user.id)}
              />
            </div>
          </div>
        </div>
      </div>
      <div class="flex flex-col grow shadow-lg">
        <div class="flex justify-between items-center shrink-0 h-16 bg-white border-b border-slate-300 px-4">
          <div class="flex flex-col gap-1.5">
            <h1 class="text-sm font-bold leading-none">
              #{@room.name}

              <.link
                class="font-normal text-xs text-blue-600 hover:text-blue-700"
                navigate={~p"/rooms/#{@room}/edit"}
              >
                Edit
              </.link>
            </h1>
            <div
              class={["text-xs leading-none h-3.5", @hide_topic? && "text-slate-600"]}
              phx-click="toggle-topic"
            >
              <%= if @hide_topic? do %>
                [Topic hidden]
              <% else %>
                {@room.topic}
              <% end %>
            </div>
          </div>
          <ul class="menu menu-horizontal w-full relative z-10 flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end">
            <li>
              {username(@current_scope.user)}
            </li>
            <li>
              <.link href={~p"/users/settings"}>Settings</.link>
            </li>
            <li>
              <.link href={~p"/users/log-out"} method="delete">Log out</.link>
            </li>
          </ul>
        </div>

        <div
          id="room-messages"
          class="flex flex-col grow overflow-auto"
          phx-hook="RoomMessages"
          phx-update="stream"
        >
          <.message
            :for={{dom_id, message} <- @streams.messages}
            current_user={@current_scope.user}
            dom_id={dom_id}
            message={message}
            timezone={@timezone}
          />
        </div>

        <div class="bg-white px-4">
          <.form
            id="new-message-form"
            for={@new_message_form}
            phx-change="validate-message"
            phx-submit="submit-message"
            class="flex items-center border-2 border-slate-300 rounded-t-sm p-1 border-b-0"
          >
            <textarea
              class="grow text-sm px-3 border-l border-slate-300 mx-1 resize-none"
              cols=""
              id="chat-message-textarea"
              name={@new_message_form[:body].name}
              phx-hook="ChatMessageTextarea"
              placeholder={"Message ##{@room.name}"}
              phx-debounce
              rows="1"
            >{Phoenix.HTML.Form.normalize_value("textarea", @new_message_form[:body].value)}</textarea>
            <button class="shrink flex items-center justify-center h-6 w-6 rounded hover:bg-slate-200">
              <.icon name="hero-paper-airplane" class="h-4 w-4" />
            </button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :current_user, Slax.Accounts.User, required: true
  attr :dom_id, :string, required: true
  attr :message, Message, required: true
  attr :timezone, :string, required: true

  defp message(assigns) do
    ~H"""
    <div id={@dom_id} class="group relative flex px-4 py-3">
      <button
        :if={@current_user.id == @message.user_id}
        class="absolute top-4 right-4 text-red-500 hover:text-red-800 cursor-pointer hidden group-hover:block"
        data-confirm="Are you sure?"
        phx-click="delete-message"
        phx-value-id={@message.id}
      >
        <.icon name="hero-trash" class="h-4 w-4" />
      </button>

      <div class="h-10 w-10 rounded shrink-0 bg-slate-300"></div>
      <div class="ml-2">
        <div class="-mt-1">
          <.link class="text-sm font-semibold hover:underline">
            <span>{username(@message.user)}</span>
          </.link>
          <span :if={@timezone} class="ml-1 text-xs text-gray-500">
            {message_timestamp(@message, @timezone)}
          </span>
          <p class="text-sm">{@message.body}</p>
        </div>
      </div>
    </div>
    """
  end

  attr :user, User, required: true
  attr :online, :boolean, default: false

  def user(assigns) do
    ~H"""
    <.link class="flex items-center h-8 hover:bg-gray-300 text-sm pl-8 pr-3" href="#">
      <div class="flex justify-center w-4">
        <%= if @online do %>
          <span class="w-2 h-2 rounded-full bg-blue-500"></span>
        <% else %>
          <span class="w-2 h-2 rounded-full border-2 border-gray-500"></span>
        <% end %>
      </div>
      <span class="ml-2 leading-none">{username(@user)}</span>
    </.link>
    """
  end

  defp username(user) do
    user.email |> String.split("@") |> List.first() |> String.capitalize()
  end

  defp message_timestamp(message, timezone) do
    message.inserted_at
    |> Timex.Timezone.convert(timezone)
    |> Timex.format!("%-l:%M %p", :strftime)
  end

  attr :active, :boolean, required: true
  attr :room, Room, required: true

  # Patch makes it so that handle_params does something
  # and that means we don't need to reload all the rooms every time
  # Patch only works on a page served by the same liveview.
  defp room_link(assigns) do
    ~H"""
    <.link
      class={[
        "flex items-center h-8 text-sm pl-8 pr-3",
        (@active && "bg-slate-300") || "hover:bg-slate-300"
      ]}
      patch={~p"/rooms/#{@room}"}
    >
      <.icon name="hero-hashtag" class="h-4 w-4" />
      <span class={["ml-2 leading-none", @active && "font-bold"]}>{@room.name}</span>
    </.link>
    """
  end

  # This is called whenever the page is refreshed
  # This is called whenever the a new live view is loaded
  def mount(_params, _session, socket) do
    rooms = Chat.list_rooms()
    users = Accounts.list_users()

    timezone = get_connect_params(socket)["timezone"]

    # Tell Presence that our current process/user needs to be tracked
    # When the process is alive, the user will be online.
    # When the process is killed, the user will turn offline
    if connected?(socket) do
      OnlineUsers.track(self(), socket.assigns.current_scope.user)
    end

    socket =
      socket
      |> assign(rooms: rooms, timezone: timezone, users: users)
      |> assign(online_users: OnlineUsers.list())

    {:ok, socket}
  end

  # This is called whenever a new topic is loaded.
  # This is called whenever the same live view is loaded
  def handle_params(params, _uri, socket) do
    # unsubscribe from the old room
    if socket.assigns[:room], do: Chat.unsubscribe_from_room(socket.assigns.room)

    # get the new room
    room =
      case Map.fetch(params, "id") do
        :error -> List.first(socket.assigns.rooms)
        {:ok, room_id} -> Chat.get_room!(room_id)
      end

    # subscribe to the new room
    Chat.subscribe_to_room(room)
    messages = Chat.list_messages_in_room(room)

    socket =
      socket
      |> assign(
        hide_topic?: false,
        page_title: "#" <> room.name,
        room: room
      )
      |> stream(:messages, messages, reset: true)
      |> assign_message_form(Chat.change_message(%Message{}, %{}, socket.assigns.current_scope))
      |> push_event("scroll_messages_to_bottom", %{})

    {:noreply, socket}
  end

  defp assign_message_form(socket, changeset) do
    assign(socket, :new_message_form, to_form(changeset))
  end

  def handle_event("toggle-topic", _params, socket) do
    {:noreply, update(socket, :hide_topic?, &(!&1))}
  end

  def handle_event("validate-message", %{"message" => message_params}, socket) do
    changeset = Chat.change_message(%Message{}, message_params, socket.assigns.current_scope)

    {:noreply, assign_message_form(socket, changeset)}
  end

  def handle_event("submit-message", %{"message" => message_params}, socket) do
    %{current_scope: current_scope, room: room} = socket.assigns

    socket =
      case Chat.create_message(room, message_params, current_scope) do
        {:ok, _message} ->
          assign_message_form(socket, Chat.change_message(%Message{}, %{}, current_scope))

        {:error, changeset} ->
          assign_message_form(socket, changeset)
      end

    {:noreply, socket}
  end

  def handle_event("delete-message", %{"id" => id}, socket) do
    Chat.delete_message_by_id(id, socket.assigns.current_scope)
  end

  # Streams are useful for rendering chunks of data (like lists)
  # on the client instead of the server.
  # This is an optimization.
  def handle_info({:new_message, message}, socket) do
    socket =
      socket
      |> stream_insert(:messages, message)
      # When you push an event with push_event/3, you’re pushing an event to the client
      |> push_event("scroll_messages_to_bottom", %{})

    {:noreply, socket}
  end

  def handle_info({:message_deleted, message}, socket) do
    {:noreply, stream_delete(socket, :messages, message)}
  end
end
