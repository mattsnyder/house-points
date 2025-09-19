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

IO.puts("Seeded database with:")
IO.puts("- 4 Harry Potter houses")
IO.puts("- 12 traits (3 per house)")
IO.puts("- Default rules (30 points per giver per day)")