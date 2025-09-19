defmodule HousePoints.Recognition.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :action, :string
    field :diff, :map

    belongs_to :actor, HousePoints.Directory.Member
    belongs_to :award, HousePoints.Recognition.Award

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:action, :diff, :actor_id, :award_id])
    |> validate_required([:action, :actor_id])
    |> validate_inclusion(:action, ["award_created", "award_revoked", "award_updated"])
  end
end
