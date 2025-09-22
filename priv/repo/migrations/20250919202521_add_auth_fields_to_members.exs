defmodule HousePoints.Repo.Migrations.AddAuthFieldsToMembers do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :microsoft_id, :string
      add :email, :string
      add :avatar_url, :string
      add :first_name, :string
      add :last_name, :string
      add :is_active, :boolean, default: true
      add :last_sign_in_at, :utc_datetime
    end

    create unique_index(:members, [:microsoft_id])
    create unique_index(:members, [:email])
    create index(:members, [:is_active])
  end
end