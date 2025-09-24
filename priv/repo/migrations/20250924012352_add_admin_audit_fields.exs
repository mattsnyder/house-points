defmodule HousePoints.Repo.Migrations.AddAdminAuditFields do
  use Ecto.Migration

  def change do
    alter table(:audit_logs) do
      add :resource_type, :string
      add :resource_id, :integer
    end

    create index(:audit_logs, [:resource_type, :resource_id])
  end
end
