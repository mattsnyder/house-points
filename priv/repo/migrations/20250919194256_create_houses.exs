defmodule HousePoints.Repo.Migrations.CreateHouses do
  use Ecto.Migration

  def change do
    create table(:houses) do
      add :name, :string, null: false
      add :color, :string, null: false
      add :crest_url, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:houses, [:name])
  end
end
