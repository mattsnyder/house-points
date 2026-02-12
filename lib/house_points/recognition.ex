defmodule HousePoints.Recognition do
  @moduledoc """
  The Recognition context handles awarding points, tracking totals, and managing audit logs.
  """

  import Ecto.Query, warn: false
  alias HousePoints.Repo
  alias HousePoints.Recognition.{Award, AuditLog, Rule}
  alias HousePoints.Directory.{Member, Trait}

  @doc """
  Awards points to a member for displaying a trait.

  ## Examples

      iex> award_points(giver, receiver, trait, 10, "Great teamwork on the project!")
      {:ok, %Award{}}

      iex> award_points(giver, giver, trait, 10, "Self-award attempt")
      {:error, %Ecto.Changeset{}}
  """
  def award_points(giver, receiver, trait, points, reason, opts \\ []) do
    with :ok <- validate_not_self_award(giver, receiver),
         :ok <- validate_daily_giver_limit(giver, points),
         {:ok, award} <- create_award(giver, receiver, trait, points, reason),
         {:ok, _audit_log} <- create_audit_log("award_created", giver, award) do
      broadcast_award_created(award)
      {:ok, award}
    end
  end

  @doc """
  Revokes an award and creates an audit trail.
  """
  def revoke_award(award, actor) do
    with {:ok, updated_award} <- soft_delete_award(award),
         {:ok, _audit_log} <- create_audit_log("award_revoked", actor, updated_award) do
      broadcast_award_revoked(updated_award)
      {:ok, updated_award}
    end
  end

  @doc """
  Gets totals by house for the current period.
  """
  def totals_by_house(opts \\ []) do
    from(a in Award,
      where: is_nil(a.deleted_at),
      group_by: a.receiver_house_id,
      select: {a.receiver_house_id, sum(a.points)}
    )
    |> apply_date_filter(opts)
    |> Repo.all()
    |> Enum.map(fn {house_id, total} ->
      %{house_id: house_id, total_points: total || 0}
    end)
  end

  @doc """
  Gets totals by member for the current period.
  """
  def totals_by_member(opts \\ []) do
    from(a in Award,
      where: is_nil(a.deleted_at),
      group_by: a.receiver_id,
      select: {a.receiver_id, sum(a.points)}
    )
    |> apply_date_filter(opts)
    |> Repo.all()
    |> Enum.map(fn {member_id, total} ->
      %{member_id: member_id, total_points: total || 0}
    end)
  end

  @doc """
  Gets totals by trait for the current period.
  """
  def totals_by_trait(opts \\ []) do
    from(a in Award,
      where: is_nil(a.deleted_at),
      group_by: a.trait_id,
      select: {a.trait_id, sum(a.points), count()}
    )
    |> apply_date_filter(opts)
    |> Repo.all()
    |> Enum.map(fn {trait_id, total, count} ->
      %{trait_id: trait_id, total_points: total || 0, award_count: count}
    end)
  end

  @doc """
  Gets weekly highlights including top members and traits.
  """
  def weekly_highlights(week_start \\ nil) do
    week_start = week_start || Date.beginning_of_week(Date.utc_today())
    week_end = Date.add(week_start, 6)

    opts = [start_date: week_start, end_date: week_end]

    %{
      house_totals: totals_by_house(opts),
      member_totals: totals_by_member(opts) |> Enum.take(10),
      trait_totals: totals_by_trait(opts),
      week_start: week_start,
      week_end: week_end
    }
  end

  @doc """
  Gets recent awards with preloaded associations.
  """
  def recent_awards(limit \\ 20) do
    from(a in Award,
      where: is_nil(a.deleted_at),
      order_by: [desc: a.inserted_at],
      limit: ^limit,
      preload: [:giver, :receiver, :trait, :receiver_house, :apparent_giver]
    )
    |> Repo.all()
  end

  @doc """
  Gets the current rules for point limits.
  """
  def current_rules do
    Repo.one(from r in Rule, order_by: [desc: r.inserted_at], limit: 1)
  end

  @doc """
  Creates new rules.
  """
  def create_rule(attrs \\ %{}) do
    %Rule{}
    |> Rule.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates existing rules.
  """
  def update_rule(%Rule{} = rule, attrs) do
    rule
    |> Rule.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a changeset for tracking rule changes.
  """
  def change_rule(%Rule{} = rule, attrs \\ %{}) do
    Rule.changeset(rule, attrs)
  end

  @doc """
  Gets recent audit logs with preloaded associations.
  """
  def list_audit_logs(limit \\ 50) do
    from(al in AuditLog,
      order_by: [desc: al.inserted_at],
      limit: ^limit,
      preload: [:actor, :award]
    )
    |> Repo.all()
  end

  @doc """
  Gets audit logs for a specific award.
  """
  def list_audit_logs_for_award(award_id) do
    from(al in AuditLog,
      where: al.award_id == ^award_id,
      order_by: [desc: al.inserted_at],
      preload: [:actor, :award]
    )
    |> Repo.all()
  end

  @doc """
  Creates an admin audit log entry.
  """
  def create_admin_audit_log(action, actor, resource_type, resource_id, diff \\ nil) do
    %AuditLog{}
    |> AuditLog.changeset(%{
      action: action,
      actor_id: actor.id,
      resource_type: resource_type,
      resource_id: resource_id,
      diff: diff
    })
    |> Repo.insert()
  end

  @doc """
  Casts a curse (negative points) on a member's house from the Room of Requirement.
  Only available to Ravenclaw members. Enforces a daily limit of -300 points.
  """
  def cast_curse(caster, receiver, points, reason) when points < 0 do
    with :ok <- validate_not_own_house(caster, receiver.house_id),
         :ok <- validate_daily_curse_limit(caster, points) do
      scapegoat = pick_random_scapegoat(caster)

      attrs = %{
        giver_id: caster.id,
        receiver_id: receiver.id,
        receiver_house_id: receiver.house_id,
        apparent_giver_id: scapegoat.id,
        points: points,
        reason: reason,
        source: "The Room of Requirement"
      }

      case %Award{} |> Award.curse_changeset(attrs) |> Repo.insert() do
        {:ok, award} ->
          create_audit_log("curse_awarded", caster, award)
          award = %{award | apparent_giver: scapegoat}
          broadcast_award_created(award)
          {:ok, award}

        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  @doc """
  Gets the total curse points a caster has used today.
  """
  def daily_curse_points_used(caster) do
    today = Date.utc_today()
    start_of_day = DateTime.new!(today, ~T[00:00:00])

    from(a in Award,
      where: a.giver_id == ^caster.id and
             a.inserted_at >= ^start_of_day and
             a.source == "The Room of Requirement" and
             is_nil(a.deleted_at),
      select: sum(a.points)
    )
    |> Repo.one() || 0
  end

  # Private functions

  defp validate_not_own_house(caster, target_house_id) do
    if caster.house_id == target_house_id do
      {:error, :cannot_curse_own_house}
    else
      :ok
    end
  end

  defp validate_daily_curse_limit(caster, points) do
    used = daily_curse_points_used(caster)
    # used is negative or 0, points is negative
    if used + points < -300 do
      {:error, :daily_curse_limit_exceeded}
    else
      :ok
    end
  end

  defp pick_random_scapegoat(caster) do
    from(m in Member,
      join: h in assoc(m, :house),
      where: m.id != ^caster.id and h.name != "Ravenclaw",
      preload: [:house]
    )
    |> Repo.all()
    |> Enum.random()
  end

  defp validate_not_self_award(%{id: id}, %{id: id}), do: {:error, :self_award_not_allowed}
  defp validate_not_self_award(_giver, _receiver), do: :ok

  defp validate_daily_giver_limit(giver, points) do
    rules = current_rules()
    if rules do
      today = Date.utc_today()
      start_of_day = DateTime.new!(today, ~T[00:00:00])

      points_given_today = from(a in Award,
        where: a.giver_id == ^giver.id and
               a.inserted_at >= ^start_of_day and
               is_nil(a.deleted_at),
        select: sum(a.points)
      ) |> Repo.one() || 0

      if points_given_today + points > rules.max_points_per_giver_per_day do
        {:error, :daily_limit_exceeded}
      else
        :ok
      end
    else
      :ok
    end
  end

  defp create_award(giver, receiver, trait, points, reason) do
    %Award{}
    |> Award.changeset(%{
      giver_id: giver.id,
      receiver_id: receiver.id,
      trait_id: trait.id,
      receiver_house_id: receiver.house_id,
      points: points,
      reason: reason
    })
    |> Repo.insert()
  end

  defp create_audit_log(action, actor, award, diff \\ nil) do
    %AuditLog{}
    |> AuditLog.changeset(%{
      action: action,
      actor_id: actor.id,
      award_id: award.id,
      diff: diff
    })
    |> Repo.insert()
  end

  defp soft_delete_award(award) do
    award
    |> Ecto.Changeset.change(deleted_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update()
  end

  defp apply_date_filter(query, opts) do
    query
    |> maybe_filter_start_date(opts[:start_date])
    |> maybe_filter_end_date(opts[:end_date])
  end

  defp maybe_filter_start_date(query, nil), do: query
  defp maybe_filter_start_date(query, start_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    from(a in query, where: a.inserted_at >= ^start_datetime)
  end

  defp maybe_filter_end_date(query, nil), do: query
  defp maybe_filter_end_date(query, end_date) do
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])
    from(a in query, where: a.inserted_at <= ^end_datetime)
  end

  defp broadcast_award_created(award) do
    Phoenix.PubSub.broadcast(HousePoints.PubSub, "awards", {:award_created, award})
  end

  defp broadcast_award_revoked(award) do
    Phoenix.PubSub.broadcast(HousePoints.PubSub, "awards", {:award_revoked, award})
  end
end