defmodule HousePoints.Auth do
  @moduledoc """
  The Auth context handles email/password authentication and user session management.
  """

  import Ecto.Query, warn: false
  alias HousePoints.Repo
  alias HousePoints.Directory.Member

  @doc """
  Registers a new member with email/password authentication.
  """
  def register_member(attrs) do
    %Member{}
    |> Member.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Authenticates a member with email and password.
  """
  def authenticate_member(email, password) do
    case get_member_by_email(email) do
      nil ->
        # Perform password check to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      member ->
        if Member.verify_password(member, password) do
          update_last_sign_in(member)
          {:ok, member}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Gets a member by their email.
  """
  def get_member_by_email(email) when is_binary(email) do
    Repo.get_by(Member, email: String.downcase(email))
    |> Repo.preload(:house)
  end

  @doc """
  Gets a member by their ID.
  """
  def get_member_by_id(id) when is_binary(id) or is_integer(id) do
    Repo.get(Member, id)
    |> Repo.preload(:house)
  end

  @doc """
  Assigns a house to a member during onboarding.
  """
  def assign_house_to_member(member, house_id) do
    member
    |> Member.house_selection_changeset(%{house_id: house_id})
    |> Repo.update()
  end

  @doc """
  Checks if a member needs to select a house (onboarding incomplete).
  """
  def needs_house_selection?(%Member{house_id: nil}), do: true
  def needs_house_selection?(%Member{}), do: false

  @doc """
  Gets all active members.
  """
  def list_active_members do
    from(m in Member, where: m.is_active == true, preload: [:house])
    |> Repo.all()
  end

  @doc """
  Updates a member's profile.
  """
  def update_member_profile(member, attrs) do
    member
    |> Member.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a member's last sign-in timestamp.
  """
  def update_last_sign_in(member) do
    member
    |> Member.changeset(%{last_sign_in_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Checks if an email is already taken.
  """
  def email_taken?(email) do
    query = from(m in Member, where: m.email == ^String.downcase(email))
    Repo.exists?(query)
  end

  @doc """
  Checks if a name is already taken.
  """
  def name_taken?(name) do
    query = from(m in Member, where: m.name == ^name)
    Repo.exists?(query)
  end
end