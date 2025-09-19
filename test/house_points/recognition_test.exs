defmodule HousePoints.RecognitionTest do
  use HousePoints.DataCase

  alias HousePoints.Recognition
  alias HousePoints.Directory.{House, Member, Trait}
  alias HousePoints.Recognition.{Award, Rule}

  describe "award_points/5" do
    setup do
      house = insert(:house)
      trait = insert(:trait, house: house)
      giver = insert(:member, house: house)
      receiver = insert(:member, house: house)
      insert(:rule, max_points_per_giver_per_day: 30)

      %{
        house: house,
        trait: trait,
        giver: giver,
        receiver: receiver
      }
    end

    test "creates award with valid data", %{giver: giver, receiver: receiver, trait: trait} do
      assert {:ok, %Award{} = award} = Recognition.award_points(
        giver,
        receiver,
        trait,
        10,
        "Great teamwork on the project!"
      )

      assert award.giver_id == giver.id
      assert award.receiver_id == receiver.id
      assert award.trait_id == trait.id
      assert award.points == 10
      assert award.reason == "Great teamwork on the project!"
      assert award.receiver_house_id == receiver.house_id
    end

    test "prevents self-awards", %{giver: giver, trait: trait} do
      assert {:error, :self_award_not_allowed} = Recognition.award_points(
        giver,
        giver,
        trait,
        10,
        "Trying to award myself"
      )
    end

    test "enforces daily giver limits", %{giver: giver, receiver: receiver, trait: trait, house: house} do
      # Create another receiver to avoid hitting the same receiver multiple times
      receiver2 = insert(:member, house: house)

      # Give 25 points first (under the 30 limit)
      assert {:ok, _award} = Recognition.award_points(giver, receiver, trait, 25, "First award")

      # Try to give 10 more points (would exceed 30 limit)
      assert {:error, :daily_limit_exceeded} = Recognition.award_points(
        giver,
        receiver2,
        trait,
        10,
        "This should fail"
      )

      # Give 5 more points (exactly at limit)
      assert {:ok, _award} = Recognition.award_points(giver, receiver2, trait, 5, "At limit")
    end

    test "creates audit log when award is created", %{giver: giver, receiver: receiver, trait: trait} do
      assert {:ok, award} = Recognition.award_points(giver, receiver, trait, 10, "Test reason")

      audit_logs = Repo.all(Recognition.AuditLog)
      assert length(audit_logs) == 1

      audit_log = hd(audit_logs)
      assert audit_log.action == "award_created"
      assert audit_log.actor_id == giver.id
      assert audit_log.award_id == award.id
    end
  end

  describe "revoke_award/2" do
    setup do
      house = insert(:house)
      trait = insert(:trait, house: house)
      giver = insert(:member, house: house)
      receiver = insert(:member, house: house)
      admin = insert(:member, house: house)

      {:ok, award} = Recognition.award_points(giver, receiver, trait, 10, "Test award")

      %{
        award: award,
        admin: admin,
        giver: giver
      }
    end

    test "soft deletes award and creates audit log", %{award: award, admin: admin} do
      assert {:ok, revoked_award} = Recognition.revoke_award(award, admin)

      assert revoked_award.deleted_at != nil

      # Check audit log was created
      audit_logs = Repo.all(from al in Recognition.AuditLog, where: al.action == "award_revoked")
      assert length(audit_logs) == 1

      audit_log = hd(audit_logs)
      assert audit_log.actor_id == admin.id
      assert audit_log.award_id == award.id
    end
  end

  describe "totals_by_house/1" do
    setup do
      house1 = insert(:house, name: "Gryffindor")
      house2 = insert(:house, name: "Hufflepuff")
      trait = insert(:trait)

      member1 = insert(:member, house: house1)
      member2 = insert(:member, house: house2)
      giver = insert(:member, house: house1)

      # Award points to different houses
      {:ok, _} = Recognition.award_points(giver, member1, trait, 10, "House 1 award")
      {:ok, _} = Recognition.award_points(giver, member2, trait, 15, "House 2 award")

      %{house1: house1, house2: house2}
    end

    test "returns totals grouped by house", %{house1: house1, house2: house2} do
      totals = Recognition.totals_by_house()

      assert length(totals) == 2

      house1_total = Enum.find(totals, &(&1.house_id == house1.id))
      house2_total = Enum.find(totals, &(&1.house_id == house2.id))

      assert house1_total.total_points == 10
      assert house2_total.total_points == 15
    end
  end

  describe "totals_by_member/1" do
    setup do
      house = insert(:house)
      trait = insert(:trait, house: house)
      giver = insert(:member, house: house)
      receiver1 = insert(:member, house: house)
      receiver2 = insert(:member, house: house)

      {:ok, _} = Recognition.award_points(giver, receiver1, trait, 10, "First award")
      {:ok, _} = Recognition.award_points(giver, receiver1, trait, 5, "Second award")
      {:ok, _} = Recognition.award_points(giver, receiver2, trait, 8, "Third award")

      %{receiver1: receiver1, receiver2: receiver2}
    end

    test "returns totals grouped by member", %{receiver1: receiver1, receiver2: receiver2} do
      totals = Recognition.totals_by_member()

      assert length(totals) == 2

      member1_total = Enum.find(totals, &(&1.member_id == receiver1.id))
      member2_total = Enum.find(totals, &(&1.member_id == receiver2.id))

      assert member1_total.total_points == 15
      assert member2_total.total_points == 8
    end
  end

  describe "weekly_highlights/1" do
    test "returns weekly summary data" do
      highlights = Recognition.weekly_highlights()

      assert Map.has_key?(highlights, :house_totals)
      assert Map.has_key?(highlights, :member_totals)
      assert Map.has_key?(highlights, :trait_totals)
      assert Map.has_key?(highlights, :week_start)
      assert Map.has_key?(highlights, :week_end)
    end
  end

  describe "recent_awards/1" do
    setup do
      house = insert(:house)
      trait = insert(:trait, house: house)
      giver = insert(:member, house: house)
      receiver = insert(:member, house: house)

      {:ok, award1} = Recognition.award_points(giver, receiver, trait, 10, "First award")
      # Sleep to ensure different timestamps
      :timer.sleep(10)
      {:ok, award2} = Recognition.award_points(giver, receiver, trait, 5, "Second award")

      %{award1: award1, award2: award2}
    end

    test "returns recent awards with preloaded associations" do
      awards = Recognition.recent_awards(10)

      assert length(awards) == 2

      # Check that both awards are present
      award_reasons = Enum.map(awards, & &1.reason)
      assert "First award" in award_reasons
      assert "Second award" in award_reasons

      # Check associations are preloaded on first award
      first_award = hd(awards)
      assert %Ecto.Association.NotLoaded{} != first_award.giver
      assert %Ecto.Association.NotLoaded{} != first_award.receiver
      assert %Ecto.Association.NotLoaded{} != first_award.trait
      assert %Ecto.Association.NotLoaded{} != first_award.receiver_house
    end
  end

  # Helper functions for creating test data
  defp insert(schema, attrs \\ %{})

  defp insert(:house, attrs) do
    attrs = Enum.into(attrs, %{})
    merged_attrs = Map.merge(%{
      name: "Test House #{System.unique_integer()}",
      color: "#123456",
      crest_url: "https://example.com/crest.jpg"
    }, attrs)

    %House{}
    |> House.changeset(merged_attrs)
    |> Repo.insert!()
  end

  defp insert(:trait, attrs) do
    attrs = Enum.into(attrs, %{})
    house = Map.get(attrs, :house) || insert(:house)

    merged_attrs = Map.merge(%{
      name: "Test Trait #{System.unique_integer()}",
      description: "A test trait",
      house_id: house.id
    }, Map.delete(attrs, :house))

    %Trait{}
    |> Trait.changeset(merged_attrs)
    |> Repo.insert!()
  end

  defp insert(:member, attrs) do
    attrs = Enum.into(attrs, %{})
    house = Map.get(attrs, :house) || insert(:house)

    merged_attrs = Map.merge(%{
      name: "Test Member #{System.unique_integer()}",
      house_id: house.id
    }, Map.delete(attrs, :house))

    %Member{}
    |> Member.changeset(merged_attrs)
    |> Repo.insert!()
  end

  defp insert(:rule, attrs) do
    attrs = Enum.into(attrs, %{})
    merged_attrs = Map.merge(%{
      max_points_per_giver_per_day: 30
    }, attrs)

    %Rule{}
    |> Rule.changeset(merged_attrs)
    |> Repo.insert!()
  end
end