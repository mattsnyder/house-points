defmodule HousePointsWeb.RecapLive do
  use HousePointsWeb, :live_view

  alias HousePoints.{Recognition, Directory}

  on_mount {HousePointsWeb.AuthPlug, :require_authenticated_user}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:selected_week, Date.beginning_of_week(Date.utc_today()))
      |> load_highlights()

    {:ok, socket}
  end

  @impl true
  def handle_event("previous_week", _params, socket) do
    new_week = Date.add(socket.assigns.selected_week, -7)
    socket = assign(socket, :selected_week, new_week) |> load_highlights()
    {:noreply, socket}
  end

  @impl true
  def handle_event("next_week", _params, socket) do
    new_week = Date.add(socket.assigns.selected_week, 7)
    socket = assign(socket, :selected_week, new_week) |> load_highlights()
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-indigo-900 via-purple-900 to-gray-900">
      <div class="container mx-auto px-4 py-8">
        <div class="text-center mb-8">
          <h1 class="text-5xl font-bold mb-4 text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 via-yellow-300 to-yellow-500">
            Weekly Chronicle
          </h1>
          <p class="text-xl text-gray-300 italic">"The best of times and the worst of times are yet to come."</p>
          <p class="text-sm text-gray-400 mt-2">- Weekly House Points Chronicle</p>
        </div>

        <!-- Week Navigation -->
        <div class="flex justify-center items-center mb-8">
          <div class="bg-gray-800/60 backdrop-blur-sm rounded-xl p-4 border border-gray-600/30">
            <div class="flex items-center space-x-6">
              <button phx-click="previous_week" class="bg-gradient-to-r from-purple-600 to-purple-500 hover:from-purple-500 hover:to-purple-400 text-white font-bold py-2 px-4 rounded-lg transition-all duration-200 shadow-lg hover:shadow-xl">
                ← Previous Week
              </button>
              <div class="text-center">
                <div class="text-lg font-bold text-yellow-400">
                  Week of <%= format_date(@selected_week) %>
                </div>
                <div class="text-sm text-gray-400">
                  <%= format_date(@selected_week) %> - <%= format_date(Date.add(@selected_week, 6)) %>
                </div>
              </div>
              <button phx-click="next_week" class="bg-gradient-to-r from-purple-600 to-purple-500 hover:from-purple-500 hover:to-purple-400 text-white font-bold py-2 px-4 rounded-lg transition-all duration-200 shadow-lg hover:shadow-xl">
                Next Week →
              </button>
            </div>
          </div>
        </div>

        <%= if @highlights && has_data?(@highlights) do %>
          <!-- Weekly Highlight Cards -->
          <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
            <!-- Leading House -->
            <%= if length(@highlights.house_totals) > 0 do %>
              <% leading_house = get_leading_house(@highlights.house_totals) %>
              <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-yellow-600/30 p-6">
                <div class="text-center">
                  <div class="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-yellow-400 to-yellow-600 rounded-full flex items-center justify-center">
                    <div class={"text-2xl font-bold #{house_symbol_bg_simple(leading_house.house_name)}"}>
                      <%= house_symbol(leading_house.house_name) %>
                    </div>
                  </div>
                  <h3 class="text-xl font-bold text-yellow-400 mb-2">House Cup Leader</h3>
                  <div class={"text-2xl font-bold #{house_text_color(leading_house.house_name)} mb-1"}>
                    <%= leading_house.house_name %>
                  </div>
                  <div class="text-gray-300 text-lg">
                    <%= leading_house.total_points %> points this week
                  </div>
                </div>
              </div>
            <% end %>

            <!-- Top Individual -->
            <%= if length(@highlights.member_totals) > 0 do %>
              <% top_member = get_top_member(@highlights.member_totals) %>
              <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-purple-600/30 p-6">
                <div class="text-center">
                  <div class="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-purple-400 to-purple-600 rounded-full flex items-center justify-center">
                    <div class="text-3xl font-bold text-purple-100">MVP</div>
                  </div>
                  <h3 class="text-xl font-bold text-purple-400 mb-2">Weekly MVP</h3>
                  <div class="text-2xl font-bold text-purple-300 mb-1">
                    <%= top_member.member_name %>
                  </div>
                  <div class={"text-lg #{house_text_color(top_member.house_name)} mb-1"}>
                    <%= top_member.house_name %>
                  </div>
                  <div class="text-gray-300">
                    <%= top_member.total_points %> points earned
                  </div>
                </div>
              </div>
            <% end %>

            <!-- Most Valued Trait -->
            <%= if length(@highlights.trait_totals) > 0 do %>
              <% top_trait = get_top_trait(@highlights.trait_totals) %>
              <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-blue-600/30 p-6">
                <div class="text-center">
                  <div class="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-blue-400 to-blue-600 rounded-full flex items-center justify-center">
                    <div class="text-3xl font-bold text-blue-100">T</div>
                  </div>
                  <h3 class="text-xl font-bold text-blue-400 mb-2">Most Valued Trait</h3>
                  <div class="text-2xl font-bold text-blue-300 mb-1">
                    <%= top_trait.trait_name %>
                  </div>
                  <div class="text-gray-300">
                    <%= top_trait.total_points %> points awarded
                  </div>
                  <div class="text-sm text-gray-400">
                    <%= top_trait.award_count %> recognitions
                  </div>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Detailed Breakdown -->
          <div class="grid lg:grid-cols-2 gap-6 mb-8">
            <!-- House Performance Breakdown -->
            <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-yellow-600/30">
              <div class="p-6">
                <h3 class="text-2xl font-bold text-yellow-400 mb-6 text-center">House Performance</h3>
                <div class="space-y-4">
                  <%= for {house_data, index} <- Enum.with_index(@highlights.house_totals) do %>
                    <div class={"flex items-center p-4 rounded-lg #{house_bg_class(house_data.house_name)}"}>
                      <div class="flex-shrink-0 w-12 text-center">
                        <div class={"w-10 h-10 rounded-full flex items-center justify-center text-lg font-bold #{rank_position_class(index)}"}>
                          <%= index + 1 %>
                        </div>
                      </div>
                      <div class="flex-1 ml-4">
                        <div class="flex items-center justify-between">
                          <div class="flex items-center">
                            <div class={"w-8 h-8 mr-3 rounded-full flex items-center justify-center text-sm font-bold #{house_symbol_bg(house_data.house_name)}"}>
                              <%= house_symbol(house_data.house_name) %>
                            </div>
                            <div>
                              <div class={"text-lg font-bold #{house_text_color(house_data.house_name)}"}><%= house_data.house_name %></div>
                              <div class="text-sm text-gray-400"><%= house_data.member_count %> members</div>
                            </div>
                          </div>
                          <div class="text-right">
                            <div class={"text-2xl font-bold #{house_text_color(house_data.house_name)}"}><%= house_data.total_points %></div>
                            <div class="text-sm text-gray-300">points</div>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <!-- Top Members This Week -->
            <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-purple-600/30">
              <div class="p-6">
                <h3 class="text-2xl font-bold text-purple-400 mb-6 text-center">Top Contributors</h3>
                <div class="space-y-4">
                  <%= for {member_data, index} <- Enum.with_index(Enum.take(@highlights.member_totals, 5)) do %>
                    <div class="flex items-center p-4 rounded-lg bg-gray-700/40">
                      <div class="flex-shrink-0 w-12 text-center">
                        <div class={"w-10 h-10 rounded-full flex items-center justify-center text-lg font-bold #{rank_position_class(index)}"}>
                          <%= index + 1 %>
                        </div>
                      </div>
                      <div class="flex-1 ml-4">
                        <div class="flex items-center justify-between">
                          <div>
                            <div class="text-lg font-bold text-purple-300"><%= member_data.member_name %></div>
                            <div class={"text-sm #{house_text_color(member_data.house_name)}"}><%= member_data.house_name %></div>
                          </div>
                          <div class="text-right">
                            <div class="text-2xl font-bold text-purple-400"><%= member_data.total_points %></div>
                            <div class="text-sm text-gray-300">points</div>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <!-- Trait Recognition Breakdown -->
          <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-blue-600/30">
            <div class="p-6">
              <h3 class="text-2xl font-bold text-blue-400 mb-6 text-center">Trait Recognition This Week</h3>
              <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
                <%= for trait_data <- Enum.take(@highlights.trait_totals, 6) do %>
                  <div class="bg-gray-700/40 rounded-lg p-4">
                    <div class="text-center">
                      <div class="text-lg font-bold text-blue-300 mb-1"><%= trait_data.trait_name %></div>
                      <div class="text-2xl font-bold text-blue-400 mb-1"><%= trait_data.total_points %></div>
                      <div class="text-sm text-gray-400"><%= trait_data.award_count %> recognitions</div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% else %>
          <!-- No Data State -->
          <div class="text-center py-16">
            <div class="w-32 h-32 mx-auto mb-6 bg-gradient-to-br from-gray-600 to-gray-800 rounded-full flex items-center justify-center">
              <div class="text-4xl font-bold text-gray-300">WR</div>
            </div>
            <h3 class="text-3xl font-bold mt-6 mb-4 text-gray-400">No Activity This Week</h3>
            <p class="text-gray-300 text-lg mb-6">This week's chronicle awaits the first recognition!</p>
            <a href="/award" class="bg-gradient-to-r from-yellow-600 to-yellow-500 hover:from-yellow-500 hover:to-yellow-400 text-gray-900 font-bold py-3 px-8 rounded-lg transition-all duration-200 shadow-lg hover:shadow-xl">
              Start Recognizing
            </a>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp load_highlights(socket) do
    highlights = Recognition.weekly_highlights(socket.assigns.selected_week)
    enriched_highlights = enrich_highlights(highlights)
    assign(socket, :highlights, enriched_highlights)
  end

  defp enrich_highlights(highlights) do
    %{
      house_totals: enrich_house_data(highlights.house_totals),
      member_totals: enrich_member_data(highlights.member_totals),
      trait_totals: enrich_trait_data(highlights.trait_totals),
      week_start: highlights.week_start,
      week_end: highlights.week_end
    }
  end

  defp enrich_house_data(house_totals) do
    Enum.map(house_totals, fn %{house_id: house_id, total_points: total_points} ->
      house = Directory.get_house!(house_id)
      member_count = Directory.count_members_by_house(house.name)

      %{
        house_name: house.name,
        total_points: total_points,
        member_count: member_count
      }
    end)
    |> Enum.sort_by(& &1.total_points, :desc)
  end

  defp enrich_member_data(member_totals) do
    Enum.map(member_totals, fn %{member_id: member_id, total_points: total_points} ->
      member = Directory.get_member!(member_id)
      house = Directory.get_house!(member.house_id)

      %{
        member_name: member.name,
        house_name: house.name,
        total_points: total_points
      }
    end)
    |> Enum.sort_by(& &1.total_points, :desc)
  end

  defp enrich_trait_data(trait_totals) do
    Enum.map(trait_totals, fn %{trait_id: trait_id, total_points: total_points, award_count: award_count} ->
      trait = Directory.get_trait!(trait_id)

      %{
        trait_name: trait.name,
        trait_description: trait.description,
        total_points: total_points,
        award_count: award_count
      }
    end)
    |> Enum.sort_by(& &1.total_points, :desc)
  end

  defp format_date(date) do
    Calendar.strftime(date, "%B %-d, %Y")
  end

  defp has_data?(highlights) do
    length(highlights.house_totals) > 0 ||
    length(highlights.member_totals) > 0 ||
    length(highlights.trait_totals) > 0
  end

  defp get_leading_house(house_totals) do
    hd(house_totals)
  end

  defp get_top_member(member_totals) do
    hd(member_totals)
  end

  defp get_top_trait(trait_totals) do
    hd(trait_totals)
  end

  # House styling helpers
  defp house_symbol(house_name) do
    case house_name do
      "Gryffindor" -> "G"
      "Hufflepuff" -> "H"
      "Ravenclaw" -> "R"
      "Slytherin" -> "S"
      _ -> "?"
    end
  end

  defp house_symbol_bg(house_name) do
    case house_name do
      "Gryffindor" -> "bg-gradient-to-br from-red-600 to-red-800 text-red-100"
      "Hufflepuff" -> "bg-gradient-to-br from-yellow-500 to-yellow-700 text-yellow-100"
      "Ravenclaw" -> "bg-gradient-to-br from-blue-600 to-blue-800 text-blue-100"
      "Slytherin" -> "bg-gradient-to-br from-green-600 to-green-800 text-green-100"
      _ -> "bg-gradient-to-br from-gray-600 to-gray-800 text-gray-100"
    end
  end

  defp house_symbol_bg_simple(house_name) do
    case house_name do
      "Gryffindor" -> "text-red-100"
      "Hufflepuff" -> "text-yellow-100"
      "Ravenclaw" -> "text-blue-100"
      "Slytherin" -> "text-green-100"
      _ -> "text-gray-100"
    end
  end

  defp house_text_color(house_name) do
    case house_name do
      "Gryffindor" -> "text-red-400"
      "Hufflepuff" -> "text-yellow-400"
      "Ravenclaw" -> "text-blue-400"
      "Slytherin" -> "text-green-400"
      _ -> "text-gray-400"
    end
  end

  defp house_bg_class(house_name) do
    case house_name do
      "Gryffindor" -> "bg-red-900/20 border border-red-600/30"
      "Hufflepuff" -> "bg-yellow-900/20 border border-yellow-600/30"
      "Ravenclaw" -> "bg-blue-900/20 border border-blue-600/30"
      "Slytherin" -> "bg-green-900/20 border border-green-600/30"
      _ -> "bg-gray-900/20 border border-gray-600/30"
    end
  end

  defp rank_position_class(index) do
    case index do
      0 -> "bg-gradient-to-br from-yellow-400 to-yellow-600 text-yellow-100"
      1 -> "bg-gradient-to-br from-gray-300 to-gray-500 text-gray-800"
      2 -> "bg-gradient-to-br from-amber-600 to-amber-800 text-amber-100"
      _ -> "bg-gradient-to-br from-gray-600 to-gray-700 text-gray-100"
    end
  end
end