defmodule SmokerGadgetWeb.PageController do
  use SmokerGadgetWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
