defmodule HousePoints.Recognition.Rule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rules" do
    field :max_points_per_giver_per_day, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [:max_points_per_giver_per_day])
    |> validate_required([:max_points_per_giver_per_day])
    |> validate_number(:max_points_per_giver_per_day, greater_than: 0)
  end
end
