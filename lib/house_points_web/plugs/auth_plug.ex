defmodule HousePointsWeb.AuthPlug do
  @moduledoc """
  Plug for handling authentication in LiveViews and controllers.
  """

  import Phoenix.Component
  import Phoenix.LiveView

  alias HousePoints.{Auth, Repo}
  alias HousePoints.Directory.Member

  def on_mount(:require_authenticated_user, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/auth")}
    end
  end

  def on_mount(:require_house_selection, _params, session, socket) do
    socket = assign_current_user(socket, session)

    case socket.assigns.current_user do
      nil ->
        {:halt, redirect(socket, to: "/auth")}

      user ->
        if Auth.needs_house_selection?(user) do
          {:cont, socket}
        else
          {:halt, redirect(socket, to: "/leaderboard")}
        end
    end
  end

  def on_mount(:assign_current_user, _params, session, socket) do
    socket = assign_current_user(socket, session)
    {:cont, socket}
  end

  defp assign_current_user(socket, session) do
    case session["current_user_id"] do
      nil ->
        assign(socket, :current_user, nil)

      user_id ->
        user = Repo.get(Member, user_id) |> Repo.preload(:house)
        assign(socket, :current_user, user)
    end
  end
end