IO.puts("=== SIMULATING LEADERBOARD LOGIC ===")

# Get the raw data
house_totals = HousePoints.Recognition.totals_by_house()
IO.puts("\nRaw house_totals:")
IO.inspect(house_totals)

# Process it like get_enriched_house_data does
house_data = Enum.map(house_totals, fn %{house_id: house_id, total_points: total_points} ->
  house = HousePoints.Directory.get_house!(house_id)
  member_count = HousePoints.Directory.count_members_by_house(house.name)

  %{
    house_name: house.name,
    total_points: total_points,
    member_count: member_count
  }
end)
|> Enum.sort_by(& &1.total_points, :desc)

max_points = if length(house_data) > 0, do: hd(house_data).total_points, else: 0
total_points = Enum.sum(Enum.map(house_data, & &1.total_points))

IO.puts("\n=== FINAL ASSIGNS ===")
IO.puts("house_totals: #{inspect(house_data)}")
IO.puts("max_house_points: #{max_points}")
IO.puts("total_points_awarded: #{total_points}")

IO.puts("\n=== TEMPLATE CONDITION ===")
condition_result = house_data && length(house_data) > 0
IO.puts("house_totals && length(house_totals) > 0 = #{condition_result}")

if condition_result do
  IO.puts("\n*** HOUSES SHOULD BE DISPLAYED ***")
  Enum.with_index(house_data)
  |> Enum.each(fn {house_data, index} ->
    medal = case index do
      0 -> "🥇"
      1 -> "🥈"
      2 -> "🥉"
      _ -> "##{index + 1}"
    end
    IO.puts("  #{medal} #{house_data.house_name} - #{house_data.total_points} points (#{house_data.member_count} members)")
  end)
else
  IO.puts("\n*** 'NO POINTS' MESSAGE SHOULD BE DISPLAYED ***")
end