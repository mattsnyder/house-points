defmodule HousePoints.Directory do
  @moduledoc """
  The Directory context manages houses, traits, and members.
  """

  import Ecto.Query, warn: false
  alias HousePoints.Repo
  alias HousePoints.Directory.{House, Member, Trait}

  ## Houses

  @doc """
  Returns the list of houses.
  """
  def list_houses do
    Repo.all(House)
  end

  @doc """
  Gets a single house.
  """
  def get_house!(id), do: Repo.get!(House, id)

  @doc """
  Creates a house.
  """
  def create_house(attrs \\ %{}) do
    %House{}
    |> House.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a house.
  """
  def update_house(%House{} = house, attrs) do
    house
    |> House.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a house.
  """
  def delete_house(%House{} = house) do
    Repo.delete(house)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking house changes.
  """
  def change_house(%House{} = house, attrs \\ %{}) do
    House.changeset(house, attrs)
  end

  ## Members

  @doc """
  Returns the list of members with their houses preloaded.
  """
  def list_members do
    Repo.all(from m in Member, preload: [:house])
  end

  @doc """
  Returns the list of active members with their houses preloaded.
  """
  def list_active_members do
    Repo.all(from m in Member, where: m.is_active == true, preload: [:house])
  end

  @doc """
  Returns the list of members for a specific house.
  """
  def list_members_by_house(house_id) do
    from(m in Member, where: m.house_id == ^house_id, preload: [:house])
    |> Repo.all()
  end

  @doc """
  Returns the count of members for a specific house by house name.
  """
  def count_members_by_house(house_name) do
    from(m in Member,
      join: h in House, on: m.house_id == h.id,
      where: h.name == ^house_name,
      select: count(m.id)
    )
    |> Repo.one()
  end

  @doc """
  Gets a single member with house preloaded.
  """
  def get_member!(id) do
    Repo.get!(Member, id) |> Repo.preload([:house])
  end

  @doc """
  Creates a member.
  """
  def create_member(attrs \\ %{}) do
    %Member{}
    |> Member.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a member.
  """
  def update_member(%Member{} = member, attrs) do
    member
    |> Member.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a member.
  """
  def delete_member(%Member{} = member) do
    Repo.delete(member)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking member changes.
  """
  def change_member(%Member{} = member, attrs \\ %{}) do
    Member.changeset(member, attrs)
  end

  ## Traits

  @doc """
  Returns the list of traits with their houses preloaded.
  """
  def list_traits do
    Repo.all(from t in Trait, preload: [:house])
  end

  @doc """
  Returns the list of traits for a specific house.
  """
  def list_traits_by_house(house_id) do
    from(t in Trait, where: t.house_id == ^house_id, preload: [:house])
    |> Repo.all()
  end

  @doc """
  Returns the list of traits not associated with any house.
  """
  def list_universal_traits do
    from(t in Trait, where: is_nil(t.house_id))
    |> Repo.all()
  end

  @doc """
  Gets a single trait with house preloaded.
  """
  def get_trait!(id) do
    Repo.get!(Trait, id) |> Repo.preload([:house])
  end

  @doc """
  Creates a trait.
  """
  def create_trait(attrs \\ %{}) do
    %Trait{}
    |> Trait.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a trait.
  """
  def update_trait(%Trait{} = trait, attrs) do
    trait
    |> Trait.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a trait.
  """
  def delete_trait(%Trait{} = trait) do
    Repo.delete(trait)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trait changes.
  """
  def change_trait(%Trait{} = trait, attrs \\ %{}) do
    Trait.changeset(trait, attrs)
  end
end