defmodule HousePoints.Repo.Migrations.CreateTraits do
  use Ecto.Migration

  def change do
    create table(:traits) do
      add :name, :string, null: false
      add :description, :string, null: false
      add :house_id, references(:houses, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:traits, [:house_id])
    create unique_index(:traits, [:name])
  end
end
