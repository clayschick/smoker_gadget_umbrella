defmodule SmokerGadgetWeb.PageControllerTest do
  use SmokerGadgetWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Input"
  end
end
