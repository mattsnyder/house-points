defmodule HousePoints.Recognition.Award do
  use Ecto.Schema
  import Ecto.Changeset

  schema "awards" do
    field :points, :integer
    field :reason, :string
    field :deleted_at, :utc_datetime

    belongs_to :giver, HousePoints.Directory.Member
    belongs_to :receiver, HousePoints.Directory.Member
    belongs_to :trait, HousePoints.Directory.Trait
    belongs_to :receiver_house, HousePoints.Directory.House
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
end
