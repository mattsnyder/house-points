defmodule HousePoints.Repo.Migrations.AllowCurseAwards do
  use Ecto.Migration

  def change do
    # Allow receiver_id and trait_id to be null for curse awards
    alter table(:awards) do
      modify :receiver_id, :bigint, null: true
      modify :trait_id, :bigint, null: true
    end

    # Drop the positive_points constraint and replace with one that allows negatives
    drop constraint(:awards, :positive_points)
    drop constraint(:awards, :no_self_awards)

    # Points must be non-zero; self-awards still blocked when receiver_id is present
    create constraint(:awards, :nonzero_points, check: "points != 0")
    create constraint(:awards, :no_self_awards, check: "receiver_id IS NULL OR giver_id != receiver_id")
  end
end
