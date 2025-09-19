defmodule HousePoints.Directory.Trait do
  use Ecto.Schema
  import Ecto.Changeset

  schema "traits" do
    field :name, :string
    field :description, :string

    belongs_to :house, HousePoints.Directory.House
    has_many :awards, HousePoints.Recognition.Award

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trait, attrs) do
    trait
    |> cast(attrs, [:name, :description, :house_id])
    |> validate_required([:name, :description])
    |> unique_constraint(:name)
  end
end
