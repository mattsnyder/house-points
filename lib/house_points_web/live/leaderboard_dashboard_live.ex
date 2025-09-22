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
          <!-- TODO: House leaderboard -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">House Standings</h2>
              <p>House leaderboard implementation coming soon...</p>
            </div>
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
        assign(socket, :house_totals, Recognition.totals_by_house())
      "individuals" ->
        assign(socket, :member_totals, Recognition.totals_by_member())
      "traits" ->
        assign(socket, :trait_totals, Recognition.totals_by_trait())
      "recent" ->
        assign(socket, :recent_awards, Recognition.recent_awards())
      _ -> socket
    end
  end
end