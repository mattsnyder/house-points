defmodule HousePointsWeb.LeaderboardDashboardLive do
  use HousePointsWeb, :live_view

  alias HousePoints.{Recognition, Directory}

  on_mount {HousePointsWeb.AuthPlug, :require_authenticated_user}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(HousePoints.PubSub, "awards")
    end

    socket =
      socket
      |> assign(:tab, "houses")
      |> load_data()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = Map.get(params, "tab", "houses")
    socket = assign(socket, :tab, tab) |> load_data()
    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    socket = push_patch(socket, to: ~p"/?tab=#{tab}")
    {:noreply, socket}
  end

  @impl true
  def handle_info({:award_created, _award}, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_info({:award_revoked, _award}, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-indigo-900 via-purple-900 to-gray-900">
      <div class="container mx-auto px-4 py-8">
        <div class="text-center mb-8">
          <h1 class="text-5xl font-bold mb-4 text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 via-yellow-300 to-yellow-500">
            House Points Championship
          </h1>
          <p class="text-xl text-gray-300 italic">"It is our choices that show what we truly are, far more than our abilities."</p>
          <p class="text-sm text-gray-400 mt-2">- Professor Dumbledore</p>
        </div>

        <!-- Navigation Tabs -->
        <div class="flex justify-center mb-8">
          <div class="bg-gray-800/60 backdrop-blur-sm rounded-xl p-2 border border-gray-600/30">
            <div class="flex space-x-2">
              <button
                phx-click="switch_tab"
                phx-value-tab="houses"
                class={"px-6 py-3 rounded-lg font-semibold transition-all duration-200 #{if @tab == "houses", do: "bg-yellow-600 text-gray-900 shadow-lg", else: "text-gray-300 hover:text-yellow-400 hover:bg-gray-700/50"}"}
              >
                Leaderboard
              </button>
              <button
                phx-click="switch_tab"
                phx-value-tab="recent"
                class={"px-6 py-3 rounded-lg font-semibold transition-all duration-200 #{if @tab == "recent", do: "bg-purple-600 text-white shadow-lg", else: "text-gray-300 hover:text-purple-400 hover:bg-gray-700/50"}"}
              >
                Recent Activity
              </button>
              <button
                phx-click="switch_tab"
                phx-value-tab="traits"
                class={"px-6 py-3 rounded-lg font-semibold transition-all duration-200 #{if @tab == "traits", do: "bg-blue-600 text-white shadow-lg", else: "text-gray-300 hover:text-blue-400 hover:bg-gray-700/50"}"}
              >
                Points By Trait
              </button>
            </div>
          </div>
        </div>

      <div>
        <%= if @tab == "houses" do %>
          <!-- House Leaderboard -->
          <div class="space-y-6">
            <!-- House Rankings -->
            <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-yellow-600/30">
              <div class="p-8">
                <h2 class="text-3xl font-bold mb-8 text-center text-yellow-400">
                  House Championship Standings
                </h2>
                <%= if has_house_totals?(@house_totals) do %>
                  <div class="space-y-4">
                    <%= for {house_data, index} <- Enum.with_index(@house_totals) do %>
                      <div class={"relative flex items-center p-6 rounded-xl border-2 shadow-lg #{house_border_class(house_data.house_name, index)} transform hover:scale-[1.02] transition-transform duration-200"}>
                        <div class="flex-shrink-0 w-16 text-center">
                          <%= case index do
                            0 -> ~H"<div class='w-12 h-12 bg-gradient-to-br from-yellow-400 to-yellow-600 rounded-full flex items-center justify-center text-yellow-900 font-bold text-lg'>1st</div>"
                            1 -> ~H"<div class='w-12 h-12 bg-gradient-to-br from-gray-300 to-gray-500 rounded-full flex items-center justify-center text-gray-800 font-bold text-lg'>2nd</div>"
                            2 -> ~H"<div class='w-12 h-12 bg-gradient-to-br from-amber-600 to-amber-800 rounded-full flex items-center justify-center text-amber-100 font-bold text-lg'>3rd</div>"
                            _ -> ~H"<div class='w-12 h-12 bg-gradient-to-br from-gray-600 to-gray-700 rounded-full flex items-center justify-center text-gray-200 font-bold text-lg'>#{index + 1}</div>"
                          end %>
                        </div>

                        <div class="flex-1 ml-4">
                          <div class="flex items-center justify-between">
                            <div class="flex items-center">
                              <div class={"w-10 h-10 mr-3 rounded-full flex items-center justify-center text-lg font-bold #{house_symbol_bg(house_data.house_name)}"}>
                                <%= house_symbol(house_data.house_name) %>
                              </div>
                              <div>
                                <h3 class={"text-xl font-bold #{house_text_color(house_data.house_name)}"}><%= house_data.house_name %></h3>
                                <p class="text-sm text-gray-400"><%= house_data.member_count %> members</p>
                              </div>
                            </div>

                            <div class="text-right">
                              <div class={"text-4xl font-bold #{house_text_color(house_data.house_name)}"}>
                                <%= house_data.total_points %>
                              </div>
                              <p class="text-sm text-gray-300">points</p>
                            </div>
                          </div>

                          <!-- Progress bar showing relative performance -->
                          <div class="mt-3">
                            <div class="flex justify-between text-xs text-gray-300 mb-1">
                              <span>House Progress</span>
                              <span><%= if @max_house_points > 0, do: round(house_data.total_points / @max_house_points * 100), else: 0 %>%</span>
                            </div>
                            <progress
                              class={"progress progress-primary h-2 #{house_progress_class(house_data.house_name)}"}
                              value={house_data.total_points}
                              max={@max_house_points || 1}
                            ></progress>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% else %>
                  <div class="text-center py-12">
                    <div class="w-24 h-24 mx-auto mb-6 bg-gradient-to-br from-yellow-400 to-yellow-600 rounded-full flex items-center justify-center">
                      <div class="text-3xl font-bold text-yellow-900">HP</div>
                    </div>
                    <h3 class="text-2xl font-bold mt-6 mb-4 text-yellow-400">The Competition Awaits!</h3>
                    <p class="text-gray-300 text-lg mb-6">Begin the house championship by recognizing exceptional achievements!</p>
                    <a href="/award" class="bg-gradient-to-r from-yellow-600 to-yellow-500 hover:from-yellow-500 hover:to-yellow-400 text-gray-900 font-bold py-3 px-8 rounded-lg transition-all duration-200 shadow-lg hover:shadow-xl">
                      Begin Awards
                    </a>
                  </div>
                <% end %>
              </div>
            </div>

            <!-- Magical Stats -->
            <%= if has_house_totals?(@house_totals) do %>
              <div class="grid md:grid-cols-3 gap-6 mt-8">
                <div class="bg-gray-800/60 backdrop-blur-sm rounded-xl p-6 border border-blue-500/30 text-center shadow-lg">
                  <div class="text-blue-300 text-sm uppercase tracking-wide mb-2">Total Magic Points</div>
                  <div class="text-4xl font-bold text-blue-400 mb-1"><%= @total_points_awarded %></div>
                  <div class="text-gray-400 text-sm">Across all houses</div>
                </div>

                <div class="bg-gray-800/60 backdrop-blur-sm rounded-xl p-6 border border-yellow-500/30 text-center shadow-lg">
                  <div class="text-yellow-300 text-sm uppercase tracking-wide mb-2">House Cup Leader</div>
                  <div class="flex justify-center mb-2">
                    <div class={"w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold #{house_symbol_bg(hd(@house_totals).house_name)}"}>
                      <%= house_symbol(hd(@house_totals).house_name) %>
                    </div>
                  </div>
                  <div class="text-yellow-400 font-bold text-lg"><%= hd(@house_totals).house_name %></div>
                </div>

                <div class="bg-gray-800/60 backdrop-blur-sm rounded-xl p-6 border border-purple-500/30 text-center shadow-lg">
                  <div class="text-purple-300 text-sm uppercase tracking-wide mb-2">Championship Gap</div>
                  <div class="text-4xl font-bold text-purple-400 mb-1">
                    <%= if length(@house_totals) > 1 do %>
                      <%= hd(@house_totals).total_points - List.last(@house_totals).total_points %>
                    <% else %>
                      0
                    <% end %>
                  </div>
                  <div class="text-gray-400 text-sm">points to close</div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>


        <%= if @tab == "traits" do %>
          <!-- Traits Leaderboard -->
          <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-blue-600/30">
            <div class="p-8">
              <h2 class="text-3xl font-bold mb-8 text-center text-blue-400">
                Most Recognized Traits
              </h2>
              <%= if length(@trait_totals || []) > 0 do %>
                <div class="grid md:grid-cols-2 gap-6">
                  <%= for {trait_data, index} <- Enum.with_index(@trait_totals) do %>
                    <div class={"relative p-6 rounded-xl border-2 shadow-lg #{trait_border_class(index)} transform hover:scale-[1.02] transition-transform duration-200"}>
                      <div class="flex items-center justify-between">
                        <!-- Trait Details -->
                        <div class="flex items-center space-x-4">
                          <!-- Rank Badge -->
                          <div class={"w-12 h-12 rounded-full flex items-center justify-center text-lg font-bold #{rank_badge_class(index)}"}>
                            <%= index + 1 %>
                          </div>

                          <!-- Trait Info -->
                          <div class="flex-1">
                            <h3 class="text-xl font-bold text-blue-400 mb-1">
                              <%= trait_data.trait_name %>
                            </h3>
                            <p class="text-sm text-gray-300 mb-2">
                              <%= trait_data.trait_description %>
                            </p>
                            <div class="flex items-center space-x-4 text-sm text-gray-400">
                              <span class="flex items-center">
                                <span class="w-2 h-2 bg-blue-400 rounded-full mr-2"></span>
                                <%= trait_data.award_count %> recognitions
                              </span>
                              <span class="flex items-center">
                                <span class="w-2 h-2 bg-purple-400 rounded-full mr-2"></span>
                                avg <%= Float.round(trait_data.total_points / max(trait_data.award_count, 1), 1) %> pts
                              </span>
                            </div>
                          </div>
                        </div>

                        <!-- Points -->
                        <div class="text-right">
                          <div class="text-3xl font-bold text-blue-400 mb-1">
                            <%= trait_data.total_points %>
                          </div>
                          <div class="text-sm text-gray-300">points</div>
                        </div>
                      </div>

                      <!-- Progress Bar -->
                      <div class="mt-4">
                        <div class="flex justify-between text-xs text-gray-300 mb-1">
                          <span>Recognition Level</span>
                          <span><%= if @max_trait_points > 0, do: round(trait_data.total_points / @max_trait_points * 100), else: 0 %>%</span>
                        </div>
                        <div class="w-full bg-gray-700 rounded-full h-2">
                          <div
                            class="bg-gradient-to-r from-blue-500 to-purple-500 h-2 rounded-full transition-all duration-300"
                            style={"width: #{if @max_trait_points > 0, do: trait_data.total_points / @max_trait_points * 100, else: 0}%"}
                          ></div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <div class="text-center py-12">
                  <div class="w-24 h-24 mx-auto mb-6 bg-gradient-to-br from-blue-600 to-blue-800 rounded-full flex items-center justify-center">
                    <div class="text-3xl font-bold text-blue-100">T</div>
                  </div>
                  <h3 class="text-2xl font-bold mt-6 mb-4 text-blue-400">No Traits Recognized Yet!</h3>
                  <p class="text-gray-300 text-lg mb-6">Start recognizing exceptional traits in your community!</p>
                  <a href="/award" class="bg-gradient-to-r from-blue-600 to-blue-500 hover:from-blue-500 hover:to-blue-400 text-white font-bold py-3 px-8 rounded-lg transition-all duration-200 shadow-lg hover:shadow-xl">
                    Award Points
                  </a>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <%= if @tab == "recent" do %>
          <!-- Recent Awards Feed -->
          <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-yellow-600/30">
            <div class="p-8">
              <h2 class="text-3xl font-bold mb-8 text-center text-yellow-400">
                Activity Feed
              </h2>
              <%= if length(@recent_awards || []) > 0 do %>
                <div class="space-y-4">
                  <%= for award <- @recent_awards do %>
                    <div class="bg-gray-700/60 backdrop-blur-sm rounded-xl p-6 border border-gray-600/30 shadow-lg">
                      <div class="flex items-center justify-between">
                        <!-- Award Details -->
                        <div class="flex items-center space-x-4">
                          <!-- House Symbol -->
                          <div class={"w-12 h-12 rounded-full flex items-center justify-center text-lg font-bold #{house_symbol_bg(award.receiver_house.name)}"}>
                            <%= house_symbol(award.receiver_house.name) %>
                          </div>

                          <!-- Award Info -->
                          <div class="flex-1">
                            <div class="flex items-center space-x-2 mb-1">
                              <span class="text-gray-300 font-medium"><%= if award.apparent_giver, do: award.apparent_giver.name, else: award.giver.name %></span>
                              <span class="text-gray-400"><%= if award.points < 0, do: "hexed", else: "awarded" %></span>
                              <span class={"font-bold #{house_text_color(award.receiver_house.name)}"}><%= award.receiver.name %></span>
                            </div>
                            <div class="text-sm text-gray-400 mb-2">
                              <span class="font-semibold text-purple-400"><%= award.points %> points</span>
                              <span class="mx-2">•</span>
                              <span class="text-blue-400"><%= if award.trait, do: award.trait.name, else: "Curse" %></span>
                            </div>
                            <div class="text-sm text-gray-300 italic">
                              "<%= award.reason %>"
                            </div>
                          </div>
                        </div>

                        <!-- Timestamp and Points -->
                        <div class="text-right">
                          <div class={"text-2xl font-bold #{if award.points < 0, do: "text-red-400", else: house_text_color(award.receiver_house.name)} mb-1"}>
                            <%= if award.points > 0, do: "+#{award.points}", else: award.points %>
                          </div>
                          <div class="text-xs text-gray-400">
                            <%= format_time_ago(award.inserted_at) %>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <div class="text-center py-12">
                  <div class="w-24 h-24 mx-auto mb-6 bg-gradient-to-br from-purple-600 to-purple-800 rounded-full flex items-center justify-center">
                    <div class="text-3xl font-bold text-purple-100">HP</div>
                  </div>
                  <h3 class="text-2xl font-bold mt-6 mb-4 text-purple-400">No Awards Yet!</h3>
                  <p class="text-gray-300 text-lg mb-6">The adventure begins with your first recognition!</p>
                  <a href="/award" class="bg-gradient-to-r from-purple-600 to-purple-500 hover:from-purple-500 hover:to-purple-400 text-white font-bold py-3 px-8 rounded-lg transition-all duration-200 shadow-lg hover:shadow-xl">
                    Award Points
                  </a>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp load_data(socket) do
    case socket.assigns.tab do
      "houses" ->
        house_data = get_enriched_house_data()
        max_points = if length(house_data) > 0, do: hd(house_data).total_points, else: 0
        total_points = Enum.sum(Enum.map(house_data, & &1.total_points))

        socket
        |> assign(:house_totals, house_data)
        |> assign(:max_house_points, max_points)
        |> assign(:total_points_awarded, total_points)

      "traits" ->
        trait_data = get_enriched_trait_data()
        max_points = if length(trait_data) > 0, do: hd(trait_data).total_points, else: 0

        socket
        |> assign(:trait_totals, trait_data)
        |> assign(:max_trait_points, max_points)
      "recent" ->
        assign(socket, :recent_awards, Recognition.recent_awards(15))
      _ -> socket
    end
  end

  defp get_enriched_house_data do
    house_totals = Recognition.totals_by_house()

    Enum.map(house_totals, fn %{house_id: house_id, total_points: total_points} ->
      # Get house name from house_id
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

  defp get_enriched_trait_data do
    trait_totals = Recognition.totals_by_trait()

    Enum.map(trait_totals, fn %{trait_id: trait_id, total_points: total_points, award_count: award_count} ->
      # Get trait details from trait_id
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

  defp house_border_class(house_name, index) do
    house_style = case house_name do
      "Gryffindor" -> "border-red-600 bg-gradient-to-br from-red-900/30 to-yellow-900/20"
      "Hufflepuff" -> "border-yellow-500 bg-gradient-to-br from-yellow-900/30 to-gray-800/20"
      "Ravenclaw" -> "border-blue-600 bg-gradient-to-br from-blue-900/30 to-gray-800/20"
      "Slytherin" -> "border-green-600 bg-gradient-to-br from-green-900/30 to-gray-800/20"
      _ -> "border-gray-600 bg-gray-800/20"
    end

    rank_glow = case index do
      0 -> "shadow-yellow-500/50 shadow-2xl"
      1 -> "shadow-gray-400/50 shadow-xl"
      2 -> "shadow-amber-600/50 shadow-lg"
      _ -> "shadow-lg"
    end

    "#{house_style} #{rank_glow}"
  end

  defp house_progress_class(house_name) do
    case house_name do
      "Gryffindor" -> "progress-error"
      "Hufflepuff" -> "progress-warning"
      "Ravenclaw" -> "progress-info"
      "Slytherin" -> "progress-success"
      _ -> "progress-primary"
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

  defp has_house_totals?(house_totals) do
    is_list(house_totals) and length(house_totals) > 0
  end

  defp format_time_ago(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime, :second)

    cond do
      diff_seconds < 60 ->
        "#{diff_seconds}s ago"
      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        "#{minutes}m ago"
      diff_seconds < 86400 ->
        hours = div(diff_seconds, 3600)
        "#{hours}h ago"
      diff_seconds < 604800 ->
        days = div(diff_seconds, 86400)
        "#{days}d ago"
      true ->
        weeks = div(diff_seconds, 604800)
        "#{weeks}w ago"
    end
  end

  defp trait_border_class(index) do
    case index do
      0 -> "border-blue-500 bg-gradient-to-br from-blue-900/30 to-purple-900/20 shadow-blue-500/50 shadow-2xl"
      1 -> "border-purple-500 bg-gradient-to-br from-purple-900/30 to-blue-900/20 shadow-purple-500/50 shadow-xl"
      2 -> "border-cyan-500 bg-gradient-to-br from-cyan-900/30 to-blue-900/20 shadow-cyan-500/50 shadow-lg"
      _ -> "border-gray-600 bg-gray-800/20 shadow-lg"
    end
  end

  defp rank_badge_class(index) do
    case index do
      0 -> "bg-gradient-to-br from-blue-400 to-blue-600 text-blue-100"
      1 -> "bg-gradient-to-br from-purple-400 to-purple-600 text-purple-100"
      2 -> "bg-gradient-to-br from-cyan-400 to-cyan-600 text-cyan-100"
      _ -> "bg-gradient-to-br from-gray-500 to-gray-700 text-gray-100"
    end
  end
end
