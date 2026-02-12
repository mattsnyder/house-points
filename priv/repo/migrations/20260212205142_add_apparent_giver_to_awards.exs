defmodule HousePoints.Repo.Migrations.AddApparentGiverToAwards do
  use Ecto.Migration

  def change do
    alter table(:awards) do
      add :apparent_giver_id, references(:members, on_delete: :nilify_all), null: true
    end
  end
end
