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
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-center">House Points Leaderboard</h1>

      <!-- Tab Navigation -->
      <div class="tabs tabs-boxed justify-center mb-8">
        <a class={["tab", @tab == "houses" && "tab-active"]}
           phx-click="switch_tab" phx-value-tab="houses">Houses</a>
        <a class={["tab", @tab == "individuals" && "tab-active"]}
           phx-click="switch_tab" phx-value-tab="individuals">Individuals</a>
        <a class={["tab", @tab == "traits" && "tab-active"]}
           phx-click="switch_tab" phx-value-tab="traits">Traits</a>
        <a class={["tab", @tab == "recent" && "tab-active"]}
           phx-click="switch_tab" phx-value-tab="recent">Recent</a>
      </div>

      <!-- Tab Content -->
      <div class="tab-content">
        <%= if @tab == "houses" do %>
          <!-- House Leaderboard -->
          <div class="space-y-6">
            <!-- House Rankings -->
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h2 class="card-title text-2xl mb-6">🏆 House Standings</h2>

                <%= if @house_totals && length(@house_totals) > 0 do %>
                  <div class="space-y-4">
                    <%= for {house_data, index} <- Enum.with_index(@house_totals) do %>
                      <div class={"flex items-center p-4 rounded-lg border-2 #{house_border_class(index)}"}>
                        <div class="flex-shrink-0 w-12 text-center">
                          <%= case index do %>
                            <% 0 -> %><span class="text-3xl">🥇</span>
                            <% 1 -> %><span class="text-3xl">🥈</span>
                            <% 2 -> %><span class="text-3xl">🥉</span>
                            <% _ -> %><span class="text-xl font-bold text-base-content/60">#<%= index + 1 %></span>
                          <% end %>
                        </div>

                        <div class="flex-1 ml-4">
                          <div class="flex items-center justify-between">
                            <div class="flex items-center">
                              <span class="text-3xl mr-3"><%= house_emoji(house_data.house_name) %></span>
                              <div>
                                <h3 class="text-xl font-bold"><%= house_data.house_name %></h3>
                                <p class="text-sm text-base-content/70"><%= house_data.member_count %> members</p>
                              </div>
                            </div>

                            <div class="text-right">
                              <div class="text-3xl font-bold text-primary">
                                <%= house_data.total_points %>
                              </div>
                              <p class="text-sm text-base-content/70">points</p>
                            </div>
                          </div>

                          <!-- Progress bar showing relative performance -->
                          <div class="mt-3">
                            <div class="flex justify-between text-xs text-base-content/60 mb-1">
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
                  <div class="text-center py-8">
                    <span class="text-6xl">🏰</span>
                    <h3 class="text-xl font-semibold mt-4 mb-2">No Points Awarded Yet</h3>
                    <p class="text-base-content/70">Start recognizing great work to see the house competition!</p>
                    <a href="/award" class="btn btn-primary mt-4">
                      🏆 Award First Points
                    </a>
                  </div>
                <% end %>
              </div>
            </div>

            <!-- Quick Stats -->
            <%= if @house_totals && length(@house_totals) > 0 do %>
              <div class="grid md:grid-cols-3 gap-4">
                <div class="stat bg-base-100 rounded-box shadow">
                  <div class="stat-title">Total Points Awarded</div>
                  <div class="stat-value text-primary"><%= @total_points_awarded %></div>
                  <div class="stat-desc">Across all houses</div>
                </div>

                <div class="stat bg-base-100 rounded-box shadow">
                  <div class="stat-title">Leading House</div>
                  <div class="stat-value text-secondary">
                    <%= house_emoji(hd(@house_totals).house_name) %>
                  </div>
                  <div class="stat-desc"><%= hd(@house_totals).house_name %></div>
                </div>

                <div class="stat bg-base-100 rounded-box shadow">
                  <div class="stat-title">Point Spread</div>
                  <div class="stat-value text-accent">
                    <%= if length(@house_totals) > 1 do %>
                      <%= hd(@house_totals).total_points - List.last(@house_totals).total_points %>
                    <% else %>
                      0
                    <% end %>
                  </div>
                  <div class="stat-desc">First to last place</div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>

        <%= if @tab == "individuals" do %>
          <!-- TODO: Individual leaderboard -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Individual Standings</h2>
              <p>Individual leaderboard implementation coming soon...</p>
            </div>
          </div>
        <% end %>

        <%= if @tab == "traits" do %>
          <!-- TODO: Trait leaderboard -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Most Recognized Traits</h2>
              <p>Trait leaderboard implementation coming soon...</p>
            </div>
          </div>
        <% end %>

        <%= if @tab == "recent" do %>
          <!-- TODO: Recent awards -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Recent Awards</h2>
              <p>Recent awards implementation coming soon...</p>
            </div>
          </div>
        <% end %>
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
      "individuals" ->
        assign(socket, :member_totals, Recognition.totals_by_member())
      "traits" ->
        assign(socket, :trait_totals, Recognition.totals_by_trait())
      "recent" ->
        assign(socket, :recent_awards, Recognition.recent_awards())
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

  defp house_emoji(house_name) do
    case house_name do
      "Gryffindor" -> "🦁"
      "Hufflepuff" -> "🦡"
      "Ravenclaw" -> "🦅"
      "Slytherin" -> "🐍"
      _ -> "🏠"
    end
  end

  defp house_border_class(index) do
    case index do
      0 -> "border-yellow-400 bg-yellow-50"
      1 -> "border-gray-400 bg-gray-50"
      2 -> "border-amber-600 bg-amber-50"
      _ -> "border-base-300 bg-base-50"
    end
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
end