defmodule FilmvisionWeb.PageController do
  use FilmvisionWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
