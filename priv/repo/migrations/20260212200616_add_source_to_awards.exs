defmodule HousePoints.Repo.Migrations.AddSourceToAwards do
  use Ecto.Migration

  def change do
    alter table(:awards) do
      add :source, :string
    end
  end
end
