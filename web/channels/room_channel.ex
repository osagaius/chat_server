defmodule ChatServer.RoomChannel do
  use Phoenix.Channel

  @initial_posts ["post1", "post2"]

  def join("room:lobby", _message, socket) do
    send self(), :after_join
    {:ok, socket}
  end
  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info(:after_join, socket) do
    push socket, "new_posts", %{value: @initial_posts}

    {:noreply, socket}
  end

  def handle_in("new:msg", msg, socket) do
    push socket, "new_posts", %{value: @initial_posts ++ msg}

    {:noreply, socket}
  end
end
