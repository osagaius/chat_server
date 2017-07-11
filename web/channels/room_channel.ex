defmodule ChatServer.RoomChannel do
  use Phoenix.Channel
  require Logger

  def join("room:lobby", _params, socket) do
    send self(), :after_join
    {:ok, socket}
  end
  def join("room:" <> room_id, _params, socket) do
    add_room(room_id)
    send self(), :after_join
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    broadcast socket, "rooms_list", %{value: get_rooms()}

    messages = get_room_messages(socket.topic);
    push_messages(messages, socket)

    {:noreply, socket}
  end

  def handle_in("new:msg", msg, socket) do
    msg = msg
    |> Map.put("timestamp", :os.system_time(:seconds))
    |> Map.put("id", UUID.uuid1())

    messages = add_room_message(socket.topic, msg)

    push_messages(messages, socket)

    {:noreply, socket}
  end

  defp get_room_messages(room) do
    messages = case res = ChatServer.Store.fetch("room:#{room}") do
      [msg|_tail] -> res
      _ ->
        # create the messages for the room
        initial_messages = []
        ChatServer.Store.set("room:#{room}", initial_messages)
        initial_messages
    end
  end

  defp add_room_message(room, msg) do
    new_messages = get_room_messages(room) ++ [msg]
    ChatServer.Store.set("room:#{room}", new_messages)
    new_messages
  end

  defp push_messages(messages, socket) do
    broadcast socket, "new_messages", %{value: messages |> Enum.take(-10)}
  end

  defp add_room(room) do
    key = "rooms_list"
    rooms = get_rooms()

    case rooms |> Enum.any?(&(&1.name == room)) do
      true ->
        # Do nothing since the room already exists
        # TODO return error instead
        nil
      false ->
        ChatServer.Store.set(key, rooms ++ [%{ name: room}])
    end

  end

  def get_rooms() do
    key = "rooms_list"
    rooms = case res = ChatServer.Store.fetch(key) do
      [msg|_tail] -> res
      _ ->
        # create the rooms, since we found none
        initial_rooms = []
        ChatServer.Store.set(key, initial_rooms)
        initial_rooms
    end
  end
end
