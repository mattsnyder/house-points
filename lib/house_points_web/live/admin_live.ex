defmodule HousePointsWeb.AdminLive do
  use HousePointsWeb, :live_view

  alias HousePoints.{Directory, Recognition}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Admin")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Admin Dashboard")
  end

  defp apply_action(socket, :houses, _params) do
    socket
    |> assign(:page_title, "Manage Houses")
    |> assign(:houses, Directory.list_houses())
  end

  defp apply_action(socket, :traits, _params) do
    socket
    |> assign(:page_title, "Manage Traits")
    |> assign(:traits, Directory.list_traits())
  end

  defp apply_action(socket, :members, _params) do
    socket
    |> assign(:page_title, "Manage Members")
    |> assign(:members, Directory.list_members())
  end

  defp apply_action(socket, :rules, _params) do
    socket
    |> assign(:page_title, "Manage Rules")
    |> assign(:current_rules, Recognition.current_rules())
  end

  defp apply_action(socket, :audit, _params) do
    socket
    |> assign(:page_title, "Audit Log")
    |> assign(:audit_logs, list_recent_audit_logs())
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8">Admin Dashboard</h1>

      <!-- Navigation -->
      <div class="tabs tabs-boxed mb-8">
        <.link navigate={~p"/admin"} class={["tab", @live_action == :index && "tab-active"]}>
          Dashboard
        </.link>
        <.link navigate={~p"/admin/houses"} class={["tab", @live_action == :houses && "tab-active"]}>
          Houses
        </.link>
        <.link navigate={~p"/admin/traits"} class={["tab", @live_action == :traits && "tab-active"]}>
          Traits
        </.link>
        <.link navigate={~p"/admin/members"} class={["tab", @live_action == :members && "tab-active"]}>
          Members
        </.link>
        <.link navigate={~p"/admin/rules"} class={["tab", @live_action == :rules && "tab-active"]}>
          Rules
        </.link>
        <.link navigate={~p"/admin/audit"} class={["tab", @live_action == :audit && "tab-active"]}>
          Audit Log
        </.link>
      </div>

      <!-- Content -->
      <%= case @live_action do %>
        <% :index -> %>
          <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h3 class="card-title">System Status</h3>
                <p>All systems operational</p>
              </div>
            </div>
            <!-- TODO: Add more dashboard widgets -->
          </div>

        <% :houses -> %>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Houses</h2>
              <!-- TODO: House management interface -->
              <p>House management coming soon...</p>
            </div>
          </div>

        <% :traits -> %>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Traits</h2>
              <!-- TODO: Trait management interface -->
              <p>Trait management coming soon...</p>
            </div>
          </div>

        <% :members -> %>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Members</h2>
              <!-- TODO: Member management interface -->
              <p>Member management coming soon...</p>
            </div>
          </div>

        <% :rules -> %>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Rules Configuration</h2>
              <!-- TODO: Rules management interface -->
              <p>Rules management coming soon...</p>
            </div>
          </div>

        <% :audit -> %>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Audit Log</h2>
              <!-- TODO: Audit log interface -->
              <p>Audit log coming soon...</p>
            </div>
          </div>
      <% end %>
    </div>
    """
  end

  defp list_recent_audit_logs do
    # TODO: Implement audit log retrieval
    []
  end
end