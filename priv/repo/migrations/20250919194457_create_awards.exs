defmodule HousePoints.Repo.Migrations.CreateAwards do
  use Ecto.Migration

  def change do
    create table(:awards) do
      add :points, :integer, null: false
      add :reason, :string, null: false
      add :giver_id, references(:members, on_delete: :restrict), null: false
      add :receiver_id, references(:members, on_delete: :restrict), null: false
      add :trait_id, references(:traits, on_delete: :restrict), null: false
      add :receiver_house_id, references(:houses, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:awards, [:giver_id])
    create index(:awards, [:receiver_id])
    create index(:awards, [:trait_id])
    create index(:awards, [:receiver_house_id])
    create index(:awards, [:inserted_at])

    create constraint(:awards, :no_self_awards, check: "giver_id != receiver_id")
    create constraint(:awards, :positive_points, check: "points > 0")
  end
end
