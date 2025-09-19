defmodule HousePoints.Repo.Migrations.CreateMembers do
  use Ecto.Migration

  def change do
    create table(:members) do
      add :name, :string, null: false
      add :house_id, references(:houses, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:members, [:house_id])
    create unique_index(:members, [:name])
  end
end
