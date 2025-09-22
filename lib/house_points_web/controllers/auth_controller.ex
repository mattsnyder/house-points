defmodule HousePointsWeb.AuthController do
  use HousePointsWeb, :controller

  alias HousePoints.Auth

  @doc """
  Handles user login with email and password
  """
  def login(conn, %{"member" => %{"email" => email, "password" => password}}) do
    case Auth.authenticate_member(email, password) do
      {:ok, member} ->
        conn =
          conn
          |> put_session(:current_user_id, member.id)
          |> put_flash(:info, "Welcome back, #{member.name}!")

        # Navigate to appropriate page based on house selection status
        if Auth.needs_house_selection?(member) do
          conn
          |> put_flash(:info, "Please select your house to continue.")
          |> redirect(to: ~p"/auth/house-selection")
        else
          conn
          |> redirect(to: ~p"/leaderboard")
        end

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid email or password.")
        |> redirect(to: ~p"/auth")
    end
  end

  @doc """
  Handles user registration with email and password
  """
  def register(conn, %{"member" => member_params}) do
    case Auth.register_member(member_params) do
      {:ok, member} ->
        conn =
          conn
          |> put_session(:current_user_id, member.id)
          |> put_flash(:info, "Welcome to House Points, #{member.name}!")

        conn
        |> redirect(to: ~p"/leaderboard")

      {:error, changeset} ->
        # Extract error messages from changeset
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        error_messages =
          Enum.map(errors, fn {field, messages} ->
            "#{String.capitalize(to_string(field))}: #{Enum.join(messages, ", ")}"
          end)
          |> Enum.join("; ")

        conn
        |> put_flash(:error, "Registration failed: #{error_messages}")
        |> redirect(to: ~p"/auth?mode=signup")
    end
  end

  @doc """
  Handles user logout
  """
  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "You have been signed out.")
    |> redirect(to: ~p"/auth")
  end
end