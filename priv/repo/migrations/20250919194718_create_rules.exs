defmodule HousePoints.Repo.Migrations.CreateRules do
  use Ecto.Migration

  def change do
    create table(:rules) do
      add :max_points_per_giver_per_day, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create constraint(:rules, :positive_max_points, check: "max_points_per_giver_per_day > 0")
  end
end
