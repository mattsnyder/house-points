# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     HousePoints.Repo.insert!(%HousePoints.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias HousePoints.Repo
alias HousePoints.Directory.{House, Trait}
alias HousePoints.Recognition.Rule

# Create the four canonical Harry Potter houses
gryffindor = Repo.insert!(%House{
  name: "Gryffindor",
  color: "#740001",
  crest_url: "https://ik.imagekit.io/hpapi/houses/gryffindor.jpg"
})

hufflepuff = Repo.insert!(%House{
  name: "Hufflepuff",
  color: "#ECB939",
  crest_url: "https://ik.imagekit.io/hpapi/houses/hufflepuff.jpg"
})

ravenclaw = Repo.insert!(%House{
  name: "Ravenclaw",
  color: "#0E1A40",
  crest_url: "https://ik.imagekit.io/hpapi/houses/ravenclaw.jpg"
})

slytherin = Repo.insert!(%House{
  name: "Slytherin",
  color: "#1A472A",
  crest_url: "https://ik.imagekit.io/hpapi/houses/slytherin.jpg"
})

# Create traits mapped to houses as specified
Repo.insert!(%Trait{
  name: "Courage",
  description: "Displaying bravery in the face of challenges or adversity",
  house_id: gryffindor.id
})

Repo.insert!(%Trait{
  name: "Initiative",
  description: "Taking action and leading by example",
  house_id: gryffindor.id
})

Repo.insert!(%Trait{
  name: "Boldness",
  description: "Making confident decisions and taking calculated risks",
  house_id: gryffindor.id
})

Repo.insert!(%Trait{
  name: "Teamwork",
  description: "Working collaboratively and supporting teammates",
  house_id: hufflepuff.id
})

Repo.insert!(%Trait{
  name: "Loyalty",
  description: "Demonstrating commitment and reliability to team and values",
  house_id: hufflepuff.id
})

Repo.insert!(%Trait{
  name: "Steadfastness",
  description: "Maintaining consistency and perseverance through challenges",
  house_id: hufflepuff.id
})

Repo.insert!(%Trait{
  name: "Curiosity",
  description: "Asking thoughtful questions and seeking to understand",
  house_id: ravenclaw.id
})

Repo.insert!(%Trait{
  name: "Insight",
  description: "Providing valuable perspectives and deep understanding",
  house_id: ravenclaw.id
})

Repo.insert!(%Trait{
  name: "Cleverness",
  description: "Finding creative and intelligent solutions to problems",
  house_id: ravenclaw.id
})

Repo.insert!(%Trait{
  name: "Ambition",
  description: "Setting high goals and working strategically to achieve them",
  house_id: slytherin.id
})

Repo.insert!(%Trait{
  name: "Resourcefulness",
  description: "Making the most of available resources and opportunities",
  house_id: slytherin.id
})

Repo.insert!(%Trait{
  name: "Drive",
  description: "Showing determination and persistence in pursuing objectives",
  house_id: slytherin.id
})

# Create default rules
Repo.insert!(%Rule{
  max_points_per_giver_per_day: 30
})

# Create members (all share the same dev password)
alias HousePoints.Directory.Member
alias HousePoints.Recognition.Award

dev_password = "qwertyqwerty_"

defmodule SeedHelpers do
  def find_or_create_member!(repo, attrs) do
    alias HousePoints.Directory.Member

    case repo.get_by(Member, email: attrs.email) do
      nil ->
        %Member{}
        |> Member.registration_changeset(attrs)
        |> repo.insert!()

      existing ->
        existing
    end
  end
end

# -- Gryffindor members --
matt = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Matthew Snyder", email: "matthew.snyder@liminalarc.co",
  password: dev_password, password_confirmation: dev_password,
  house_id: gryffindor.id, first_name: "Matthew", last_name: "Snyder"
})

harry = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Harry Potter", email: "harry@hogwarts.edu",
  password: dev_password, password_confirmation: dev_password,
  house_id: gryffindor.id, first_name: "Harry", last_name: "Potter"
})

neville = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Neville Longbottom", email: "neville@hogwarts.edu",
  password: dev_password, password_confirmation: dev_password,
  house_id: gryffindor.id, first_name: "Neville", last_name: "Longbottom"
})

# -- Hufflepuff members --
cedric = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Cedric Diggory", email: "cedric@hogwarts.edu",
  password: dev_password, password_confirmation: dev_password,
  house_id: hufflepuff.id, first_name: "Cedric", last_name: "Diggory"
})

tonks = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Nymphadora Tonks", email: "tonks@hogwarts.edu",
  password: dev_password, password_confirmation: dev_password,
  house_id: hufflepuff.id, first_name: "Nymphadora", last_name: "Tonks"
})

newt = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Newt Scamander", email: "newt@hogwarts.edu",
  password: dev_password, password_confirmation: dev_password,
  house_id: hufflepuff.id, first_name: "Newt", last_name: "Scamander"
})

# -- Ravenclaw members --
luna = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Luna Lovegood", email: "luna@hogwarts.edu",
  password: dev_password, password_confirmation: dev_password,
  house_id: ravenclaw.id, first_name: "Luna", last_name: "Lovegood"
})

cho = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Cho Chang", email: "cho@hogwarts.edu",
  password: dev_password, password_confirmation: dev_password,
  house_id: ravenclaw.id, first_name: "Cho", last_name: "Chang"
})

padma = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Padma Patil", email: "padma@hogwarts.edu",
  password: dev_password, password_confirmation: dev_password,
  house_id: ravenclaw.id, first_name: "Padma", last_name: "Patil"
})

# -- Slytherin members --
draco = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Draco Malfoy", email: "draco@hogwarts.edu",
  password: dev_password, password_confirmation: dev_password,
  house_id: slytherin.id, first_name: "Draco", last_name: "Malfoy"
})

pansy = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Pansy Parkinson", email: "pansy@hogwarts.edu",
  password: dev_password, password_confirmation: dev_password,
  house_id: slytherin.id, first_name: "Pansy", last_name: "Parkinson"
})

blaise = SeedHelpers.find_or_create_member!(Repo, %{
  name: "Blaise Zabini", email: "blaise@hogwarts.edu",
  password: dev_password, password_confirmation: dev_password,
  house_id: slytherin.id, first_name: "Blaise", last_name: "Zabini"
})

# Load all traits for award seeding
all_traits = Repo.all(Trait) |> Repo.preload(:house)
traits_by_house = Enum.group_by(all_traits, & &1.house_id)

# Helper to pick a random trait for a house
pick_trait = fn house_id ->
  traits_by_house[house_id] |> Enum.random()
end

# Seed awards — a mix of points across houses and days
# We'll create awards over the past 2 weeks for realistic leaderboard data
awards_data = [
  # Gryffindor receiving
  {luna, harry, :gryffindor, 15, "Led the defense study group with incredible patience"},
  {cedric, neville, :gryffindor, 10, "Stood up to present despite being nervous — true courage"},
  {draco, harry, :gryffindor, 5, "Grudgingly admit the catch was impressive"},
  {tonks, neville, :gryffindor, 20, "Organized the entire charity event single-handedly"},
  {cho, matt, :gryffindor, 12, "Took the lead on a difficult cross-team project"},
  {padma, harry, :gryffindor, 8, "Volunteered for the hardest assignment without hesitation"},

  # Hufflepuff receiving
  {harry, cedric, :hufflepuff, 25, "Helped three new team members get onboarded this week"},
  {luna, tonks, :hufflepuff, 18, "Always the first to offer help when someone is stuck"},
  {matt, newt, :hufflepuff, 10, "Brought the whole team together for a great retrospective"},
  {draco, cedric, :hufflepuff, 7, "Fair play during the competition, respected the rules"},
  {neville, tonks, :hufflepuff, 15, "Stayed late to help finish the group project"},
  {blaise, newt, :hufflepuff, 9, "Consistently reliable — never misses a deadline"},

  # Ravenclaw receiving
  {harry, luna, :ravenclaw, 20, "Asked the question nobody else thought of in the review"},
  {cedric, cho, :ravenclaw, 14, "Found a creative workaround for the blocked integration"},
  {matt, padma, :ravenclaw, 11, "Incredible research presentation that taught us all something"},
  {neville, luna, :ravenclaw, 8, "Spotted the subtle bug everyone else missed"},
  {tonks, cho, :ravenclaw, 16, "Designed an elegant solution to a complex problem"},
  {pansy, padma, :ravenclaw, 6, "Sharp analysis of the quarterly metrics"},

  # Slytherin receiving
  {harry, draco, :slytherin, 10, "Set an ambitious sprint goal and actually hit it"},
  {luna, pansy, :slytherin, 12, "Negotiated a great deal with the vendor"},
  {cedric, blaise, :slytherin, 9, "Found a way to reuse existing code and saved days of work"},
  {matt, draco, :slytherin, 15, "Drove the strategy session with clear vision"},
  {cho, pansy, :slytherin, 7, "Turned a setback into an opportunity for the team"},
  {newt, blaise, :slytherin, 11, "Persistent debugging finally cracked the production issue"},
]

# Only seed awards if none exist yet
if Repo.aggregate(Award, :count, :id) == 0 do
  for {giver, receiver, _house_key, points, reason} <- awards_data do
    trait = pick_trait.(receiver.house_id)

    # Spread awards across the past 14 days
    days_ago = Enum.random(0..13)
    inserted_at =
      Date.utc_today()
      |> Date.add(-days_ago)
      |> DateTime.new!(~T[09:00:00])
      |> DateTime.add(Enum.random(0..28800), :second)
      |> DateTime.truncate(:second)

    %Award{}
    |> Award.changeset(%{
      giver_id: giver.id,
      receiver_id: receiver.id,
      trait_id: trait.id,
      receiver_house_id: receiver.house_id,
      points: points,
      reason: reason
    })
    |> Ecto.Changeset.put_change(:inserted_at, inserted_at)
    |> Repo.insert!()
  end

  IO.puts("- 24 awards seeded across 14 days")
else
  IO.puts("- Awards already exist, skipping")
end

IO.puts("\nSeeded database with:")
IO.puts("- 4 Harry Potter houses")
IO.puts("- 12 traits (3 per house)")
IO.puts("- Default rules (30 points per giver per day)")
IO.puts("- 13 members (3 per house + admin)")
IO.puts("- 24 awards across all houses")
IO.puts("\nAll dev accounts use password: #{dev_password}")
IO.puts("Ravenclaw accounts (for Room of Requirement testing):")
IO.puts("  luna@hogwarts.edu / cho@hogwarts.edu / padma@hogwarts.edu")