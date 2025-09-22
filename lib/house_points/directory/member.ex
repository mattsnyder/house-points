defmodule HousePoints.Directory.Member do
  use Ecto.Schema
  import Ecto.Changeset

  schema "members" do
    field :name, :string
    field :microsoft_id, :string
    field :email, :string
    field :avatar_url, :string
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
    |> cast(attrs, [:name, :house_id, :microsoft_id, :email, :avatar_url, :first_name, :last_name, :is_active, :last_sign_in_at])
    |> validate_required([:name])
    |> validate_email(:email)
    |> unique_constraint(:name)
    |> unique_constraint(:microsoft_id)
    |> unique_constraint(:email)
  end

  @doc """
  Changeset for creating a member from Microsoft auth data
  """
  def auth_changeset(member, attrs) do
    member
    |> cast(attrs, [:microsoft_id, :email, :avatar_url, :first_name, :last_name, :name, :last_sign_in_at])
    |> validate_required([:microsoft_id, :email, :name])
    |> validate_email(:email)
    |> unique_constraint(:microsoft_id)
    |> unique_constraint(:email)
    |> put_change(:is_active, true)
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
end
