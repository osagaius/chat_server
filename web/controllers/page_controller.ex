defmodule ChatServer.PageController do
  use ChatServer.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
