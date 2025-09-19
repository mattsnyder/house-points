defmodule HousePointsWeb.PageController do
  use HousePointsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
