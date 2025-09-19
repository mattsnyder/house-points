defmodule HousePoints.Repo.Migrations.AddDeletedAtToAwards do
  use Ecto.Migration

  def change do
    alter table(:awards) do
      add :deleted_at, :utc_datetime
    end

    create index(:awards, [:deleted_at])
  end
end