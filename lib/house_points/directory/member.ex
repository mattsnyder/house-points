defmodule HousePoints.Directory.Member do
  use Ecto.Schema
  import Ecto.Changeset

  schema "members" do
    field :name, :string

    belongs_to :house, HousePoints.Directory.House
    has_many :awards_given, HousePoints.Recognition.Award, foreign_key: :giver_id
    has_many :awards_received, HousePoints.Recognition.Award, foreign_key: :receiver_id
    has_many :audit_logs, HousePoints.Recognition.AuditLog, foreign_key: :actor_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:name, :house_id])
    |> validate_required([:name, :house_id])
    |> unique_constraint(:name)
  end
end
