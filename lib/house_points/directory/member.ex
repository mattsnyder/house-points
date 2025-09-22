defmodule HousePoints.Directory.Member do
  use Ecto.Schema
  import Ecto.Changeset

  schema "members" do
    field :name, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :first_name, :string
    field :last_name, :string
    field :is_active, :boolean, default: true
    field :last_sign_in_at, :utc_datetime

    belongs_to :house, HousePoints.Directory.House
    has_many :awards_given, HousePoints.Recognition.Award, foreign_key: :giver_id
    has_many :awards_received, HousePoints.Recognition.Award, foreign_key: :receiver_id
    has_many :audit_logs, HousePoints.Recognition.AuditLog, foreign_key: :actor_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:name, :house_id, :email, :first_name, :last_name, :is_active, :last_sign_in_at])
    |> validate_required([:name, :email])
    |> validate_email(:email)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
  end

  @doc """
  Changeset for user registration with email/password
  """
  def registration_changeset(member, attrs) do
    member
    |> cast(attrs, [:name, :email, :password, :password_confirmation, :first_name, :last_name])
    |> validate_required([:name, :email, :password])
    |> validate_email(:email)
    |> validate_length(:password, min: 8, message: "must be at least 8 characters")
    |> validate_confirmation(:password, message: "does not match password")
    |> unique_constraint(:email)
    |> unique_constraint(:name)
    |> hash_password()
  end

  @doc """
  Changeset for user login
  """
  def login_changeset(member, attrs) do
    member
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_email(:email)
  end

  @doc """
  Changeset for house selection during onboarding
  """
  def house_selection_changeset(member, attrs) do
    member
    |> cast(attrs, [:house_id])
    |> validate_required([:house_id])
  end

  defp validate_email(changeset, field) do
    changeset
    |> validate_format(field, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset
      password ->
        changeset
        |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)
    end
  end

  @doc """
  Verifies the password against the hashed password
  """
  def verify_password(member, password) do
    Bcrypt.verify_pass(password, member.hashed_password)
  end

  @doc """
  Returns true if the member needs to select a house
  """
  def needs_house_selection?(%__MODULE__{house_id: nil}), do: true
  def needs_house_selection?(%__MODULE__{}), do: false
end
