defmodule SlaxWeb.OnlineUsers do
  alias SlaxWeb.Presence

  @topic "online_users"

  # Tells us which processes/users are active/online
  # We only need the count of the current metas instead of the actual data
  def list() do
    @topic
    |> Presence.list()
    |> Enum.into(%{}, fn {user_id, %{metas: metas}} ->
      {String.to_integer(user_id), length(metas)}
    end)
  end

  # Marks when a process/user is active/online
  def track(pid, user) do
    {:ok, _} = Presence.track(pid, @topic, user.id, %{})
  end

  # If the metas is greater than 0, the user is online.
  # A meta is a browser tab
  def online?(online_users, user_id) do
    Map.get(online_users, user_id, 0) > 0
  end
end
