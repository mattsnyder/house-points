defmodule HousePointsWeb.RecapLive do
  use HousePointsWeb, :live_view

  alias HousePoints.Recognition

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
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-center">Weekly Recap</h1>

      <!-- Week Navigation -->
      <div class="flex justify-center items-center mb-8">
        <button phx-click="previous_week" class="btn btn-outline">
          ← Previous Week
        </button>
        <div class="mx-6 text-lg font-semibold">
          Week of <%= Date.to_string(@selected_week) %>
        </div>
        <button phx-click="next_week" class="btn btn-outline">
          Next Week →
        </button>
      </div>

      <%= if @highlights do %>
        <!-- Weekly Stats Cards -->
        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
          <!-- House Winner -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h3 class="card-title">🏆 Leading House</h3>
              <!-- TODO: Display leading house -->
              <p>House standings for the week...</p>
            </div>
          </div>

          <!-- MVP -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h3 class="card-title">⭐ MVP</h3>
              <!-- TODO: Display top individual -->
              <p>Top individual for the week...</p>
            </div>
          </div>

          <!-- Most Popular Trait -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h3 class="card-title">💎 Most Valued Trait</h3>
              <!-- TODO: Display most awarded trait -->
              <p>Most recognized trait this week...</p>
            </div>
          </div>
        </div>

        <!-- Detailed Breakdown -->
        <div class="grid lg:grid-cols-2 gap-6">
          <!-- House Breakdown -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h3 class="card-title">House Performance</h3>
              <!-- TODO: House breakdown chart/table -->
              <p>Detailed house performance coming soon...</p>
            </div>
          </div>

          <!-- Trait Breakdown -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h3 class="card-title">Trait Recognition</h3>
              <!-- TODO: Trait breakdown chart/table -->
              <p>Trait recognition breakdown coming soon...</p>
            </div>
          </div>
        </div>
      <% else %>
        <div class="text-center">
          <p class="text-lg">No data available for this week.</p>
        </div>
      <% end %>
    </div>
    """
  end

  defp load_highlights(socket) do
    highlights = Recognition.weekly_highlights(socket.assigns.selected_week)
    assign(socket, :highlights, highlights)
  end
end