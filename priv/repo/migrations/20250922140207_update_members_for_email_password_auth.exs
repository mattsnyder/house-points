defmodule HousePoints.Repo.Migrations.UpdateMembersForEmailPasswordAuth do
  use Ecto.Migration

  def change do
    alter table(:members) do
      # Remove Microsoft OAuth fields
      remove_if_exists :microsoft_id, :string
      remove_if_exists :avatar_url, :string

      # Add password authentication fields
      add :hashed_password, :string

      # Make email required by adding NOT NULL constraint
      modify :email, :string, null: false
    end

    # Create unique index on email if it doesn't exist
    create_if_not_exists unique_index(:members, [:email])
  end
end