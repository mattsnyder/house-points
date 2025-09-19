defmodule HousePoints.Directory.House do
  use Ecto.Schema
  import Ecto.Changeset

  schema "houses" do
    field :name, :string
    field :color, :string
    field :crest_url, :string

    has_many :members, HousePoints.Directory.Member
    has_many :traits, HousePoints.Directory.Trait
    has_many :awards, HousePoints.Recognition.Award, foreign_key: :receiver_house_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(house, attrs) do
    house
    |> cast(attrs, [:name, :color, :crest_url])
    |> validate_required([:name, :color, :crest_url])
    |> unique_constraint(:name)
  end
end
