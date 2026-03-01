defmodule ChatControllerWeb.PageController do
  use ChatControllerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
