defmodule HousePoints.Recognition.Award do
  use Ecto.Schema
  import Ecto.Changeset

  schema "awards" do
    field :points, :integer
    field :reason, :string
    field :deleted_at, :utc_datetime
    field :source, :string

    belongs_to :giver, HousePoints.Directory.Member
    belongs_to :receiver, HousePoints.Directory.Member
    belongs_to :trait, HousePoints.Directory.Trait
    belongs_to :receiver_house, HousePoints.Directory.House
    belongs_to :apparent_giver, HousePoints.Directory.Member
    has_many :audit_logs, HousePoints.Recognition.AuditLog

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(award, attrs) do
    award
    |> cast(attrs, [:points, :reason, :giver_id, :receiver_id, :trait_id, :receiver_house_id])
    |> validate_required([:points, :reason, :giver_id, :receiver_id, :trait_id, :receiver_house_id])
    |> validate_number(:points, greater_than: 0, less_than_or_equal_to: 50)
    |> validate_length(:reason, min: 5, max: 500)
  end

  @doc """
  Changeset for client-side form validation. Does not require receiver_house_id
  since it will be set server-side based on the receiver.
  """
  def form_changeset(award, attrs) do
    award
    |> cast(attrs, [:points, :reason, :giver_id, :receiver_id, :trait_id])
    |> validate_required([:points, :reason, :giver_id, :receiver_id, :trait_id])
    |> validate_number(:points, greater_than: 0, less_than_or_equal_to: 50)
    |> validate_length(:reason, min: 5, max: 500)
  end

  @doc """
  Changeset for curse awards (negative points) from the Room of Requirement.
  """
  def curse_changeset(award, attrs) do
    award
    |> cast(attrs, [:points, :reason, :giver_id, :receiver_id, :receiver_house_id, :source, :apparent_giver_id])
    |> validate_required([:points, :reason, :giver_id, :receiver_id, :receiver_house_id])
    |> validate_number(:points, less_than: 0, greater_than_or_equal_to: -300)
    |> validate_length(:reason, min: 5, max: 500)
  end

  @doc """
  Changeset for curse form validation (client-side).
  """
  def curse_form_changeset(award, attrs) do
    award
    |> cast(attrs, [:points, :reason, :receiver_id])
    |> validate_required([:points, :reason, :receiver_id])
    |> validate_number(:points, less_than: 0, greater_than_or_equal_to: -300)
    |> validate_length(:reason, min: 5, max: 500)
  end
end
