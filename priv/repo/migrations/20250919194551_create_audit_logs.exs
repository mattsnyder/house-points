defmodule HousePoints.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :action, :string, null: false
      add :diff, :map
      add :actor_id, references(:members, on_delete: :restrict), null: false
      add :award_id, references(:awards, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:audit_logs, [:actor_id])
    create index(:audit_logs, [:award_id])
    create index(:audit_logs, [:inserted_at])
  end
end
