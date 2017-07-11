defmodule ChatServer.RoomChannel do
  use Phoenix.Channel
  require Logger

  @initial_posts ["post1", "post2"]

  def join("room:lobby", _message, socket) do
    send self(), :after_join
    {:ok, socket}
  end
  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info(:after_join, socket) do
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

  def get_room_messages(room) do
    messages = case res = ChatServer.Store.fetch(room) do
      [msg|_tail] -> res
      _ ->
        # create the messages for the room
        initial_messages = []
        ChatServer.Store.set(room, initial_messages)
        initial_messages
    end
  end

  def add_room_message(room, msg) do
    new_messages = get_room_messages(room) ++ [msg]
    ChatServer.Store.set(room, new_messages)
    new_messages
  end

  def push_messages(messages, socket) do
    Logger.warn("pushing messages #{inspect messages}")
    broadcast socket, "new_messages", %{value: messages |> Enum.take(-10)}
  end
end
