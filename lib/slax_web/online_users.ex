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

  # A presence is really just a wrapper around PubSub
  def subscribe() do
    Phoenix.PubSub.subscribe(Slax.PubSub, @topic)
  end

  # This updates our current process in real time
  # that someone has entered or left without relying on a browser refresh
  def update(online_users, %{joins: joins, leaves: leaves}) do
    online_users
    |> process_updates(joins, &Kernel.+/2)
    |> process_updates(leaves, &Kernel.-/2)
  end

  defp process_updates(online_users, updates, operation) do
    Enum.reduce(updates, online_users, fn {user_id, %{metas: metas}}, acc ->
      Map.update(acc, String.to_integer(user_id), length(metas), &operation.(&1, length(metas)))
    end)
  end
end
