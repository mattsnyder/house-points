defmodule HousePointsWeb.AdminLive do
  use HousePointsWeb, :live_view
  import Ecto.Query

  alias HousePoints.{Directory, Recognition, Repo}
  alias HousePoints.Directory.{House, Member, Trait}
  alias HousePoints.Recognition.{Rule, Award}

  on_mount {HousePointsWeb.AuthPlug, :require_authenticated_user}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Admin")
     |> assign(:form, nil)
     |> assign(:editing_item, nil)
     |> assign(:show_modal, false)
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Admin Dashboard")
    |> assign(:stats, get_dashboard_stats())
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
    |> assign(:houses_for_select, houses_for_select())
  end

  defp apply_action(socket, :members, _params) do
    socket
    |> assign(:page_title, "Manage Members")
    |> assign(:members, Directory.list_members())
    |> assign(:houses_for_select, houses_for_select())
  end

  defp apply_action(socket, :rules, _params) do
    current_rules = Recognition.current_rules()

    socket
    |> assign(:page_title, "Manage Rules")
    |> assign(:current_rules, current_rules)
    |> assign(:form, rules_form(current_rules))
  end

  defp apply_action(socket, :audit, _params) do
    socket
    |> assign(:page_title, "Audit Log")
    |> assign(:audit_logs, Recognition.list_audit_logs(100))
  end

  @impl true
  def handle_event("edit_house", %{"id" => id}, socket) do
    house = Directory.get_house!(id)
    changeset = Directory.change_house(house)

    socket =
      socket
      |> assign(:editing_item, house)
      |> assign(:form, to_form(changeset))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  def handle_event("new_house", _params, socket) do
    changeset = Directory.change_house(%House{})

    socket =
      socket
      |> assign(:editing_item, %House{})
      |> assign(:form, to_form(changeset))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  def handle_event("save_house", %{"house" => house_params}, socket) do
    case socket.assigns.editing_item.id do
      nil ->
        case Directory.create_house(house_params) do
          {:ok, _house} ->
            socket =
              socket
              |> put_flash(:info, "House created successfully!")
              |> assign(:show_modal, false)
              |> assign(:houses, Directory.list_houses())
            {:noreply, socket}

          {:error, changeset} ->
            socket = assign(socket, :form, to_form(changeset))
            {:noreply, socket}
        end

      _id ->
        case Directory.update_house(socket.assigns.editing_item, house_params) do
          {:ok, _house} ->
            socket =
              socket
              |> put_flash(:info, "House updated successfully!")
              |> assign(:show_modal, false)
              |> assign(:houses, Directory.list_houses())
            {:noreply, socket}

          {:error, changeset} ->
            socket = assign(socket, :form, to_form(changeset))
            {:noreply, socket}
        end
    end
  end

  def handle_event("edit_trait", %{"id" => id}, socket) do
    trait = Directory.get_trait!(id)
    changeset = Directory.change_trait(trait)

    socket =
      socket
      |> assign(:editing_item, trait)
      |> assign(:form, to_form(changeset))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  def handle_event("new_trait", _params, socket) do
    changeset = Directory.change_trait(%Trait{})

    socket =
      socket
      |> assign(:editing_item, %Trait{})
      |> assign(:form, to_form(changeset))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  def handle_event("save_trait", %{"trait" => trait_params}, socket) do
    case socket.assigns.editing_item.id do
      nil ->
        case Directory.create_trait(trait_params) do
          {:ok, _trait} ->
            socket =
              socket
              |> put_flash(:info, "Trait created successfully!")
              |> assign(:show_modal, false)
              |> assign(:traits, Directory.list_traits())
            {:noreply, socket}

          {:error, changeset} ->
            socket = assign(socket, :form, to_form(changeset))
            {:noreply, socket}
        end

      _id ->
        case Directory.update_trait(socket.assigns.editing_item, trait_params) do
          {:ok, _trait} ->
            socket =
              socket
              |> put_flash(:info, "Trait updated successfully!")
              |> assign(:show_modal, false)
              |> assign(:traits, Directory.list_traits())
            {:noreply, socket}

          {:error, changeset} ->
            socket = assign(socket, :form, to_form(changeset))
            {:noreply, socket}
        end
    end
  end

  def handle_event("edit_member", %{"id" => id}, socket) do
    member = Directory.get_member!(id)
    changeset = Directory.change_member(member)

    socket =
      socket
      |> assign(:editing_item, member)
      |> assign(:form, to_form(changeset))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  def handle_event("save_member", %{"member" => member_params}, socket) do
    case Directory.update_member(socket.assigns.editing_item, member_params) do
      {:ok, _member} ->
        socket =
          socket
          |> put_flash(:info, "Member updated successfully!")
          |> assign(:show_modal, false)
          |> assign(:members, Directory.list_members())
        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, :form, to_form(changeset))
        {:noreply, socket}
    end
  end

  def handle_event("save_rules", %{"rule" => rule_params}, socket) do
    case socket.assigns.current_rules do
      nil ->
        case Recognition.create_rule(rule_params) do
          {:ok, rules} ->
            socket =
              socket
              |> put_flash(:info, "Rules created successfully!")
              |> assign(:current_rules, rules)
              |> assign(:form, rules_form(rules))
            {:noreply, socket}

          {:error, changeset} ->
            socket = assign(socket, :form, to_form(changeset))
            {:noreply, socket}
        end

      rules ->
        case Recognition.update_rule(rules, rule_params) do
          {:ok, updated_rules} ->
            socket =
              socket
              |> put_flash(:info, "Rules updated successfully!")
              |> assign(:current_rules, updated_rules)
              |> assign(:form, rules_form(updated_rules))
            {:noreply, socket}

          {:error, changeset} ->
            socket = assign(socket, :form, to_form(changeset))
            {:noreply, socket}
        end
    end
  end

  def handle_event("close_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_modal, false)
      |> assign(:editing_item, nil)
      |> assign(:form, nil)

    {:noreply, socket}
  end

  def handle_event("prevent_close", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("validate_house", %{"house" => house_params}, socket) do
    changeset =
      socket.assigns.editing_item
      |> Directory.change_house(house_params)
      |> Map.put(:action, :validate)

    socket = assign(socket, :form, to_form(changeset))
    {:noreply, socket}
  end

  def handle_event("validate_trait", %{"trait" => trait_params}, socket) do
    changeset =
      socket.assigns.editing_item
      |> Directory.change_trait(trait_params)
      |> Map.put(:action, :validate)

    socket = assign(socket, :form, to_form(changeset))
    {:noreply, socket}
  end

  def handle_event("validate_member", %{"member" => member_params}, socket) do
    changeset =
      socket.assigns.editing_item
      |> Directory.change_member(member_params)
      |> Map.put(:action, :validate)

    socket = assign(socket, :form, to_form(changeset))
    {:noreply, socket}
  end

  def handle_event("validate_rules", %{"rule" => rule_params}, socket) do
    changeset =
      (socket.assigns.current_rules || %Rule{})
      |> Recognition.change_rule(rule_params)
      |> Map.put(:action, :validate)

    socket = assign(socket, :form, to_form(changeset))
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-indigo-900 via-purple-900 to-gray-900">
      <div class="container mx-auto px-4 py-8 max-w-7xl">
        <div class="text-center mb-8">
          <h1 class="text-5xl font-bold mb-4 text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 via-yellow-300 to-yellow-500">
            🏰 Ministry of Magic - Admin Portal
          </h1>
          <p class="text-xl text-gray-300">"Managing Hogwarts affairs with magical precision"</p>
        </div>

        <!-- Navigation -->
        <div class="mb-8">
          <div class="flex flex-wrap justify-center gap-2 p-2 bg-gray-800/60 backdrop-blur-sm rounded-xl border border-yellow-600/30">
            <.link navigate={~p"/admin"} class={"px-4 py-2 rounded-lg text-sm font-medium transition-colors duration-200 " <> if(@live_action == :index, do: "bg-yellow-600 text-gray-900", else: "text-gray-300 hover:bg-gray-700 hover:text-yellow-400")}>
              📊 Dashboard
            </.link>
            <.link navigate={~p"/admin/houses"} class={"px-4 py-2 rounded-lg text-sm font-medium transition-colors duration-200 " <> if(@live_action == :houses, do: "bg-yellow-600 text-gray-900", else: "text-gray-300 hover:bg-gray-700 hover:text-yellow-400")}>
              🏠 Houses
            </.link>
            <.link navigate={~p"/admin/traits"} class={"px-4 py-2 rounded-lg text-sm font-medium transition-colors duration-200 " <> if(@live_action == :traits, do: "bg-yellow-600 text-gray-900", else: "text-gray-300 hover:bg-gray-700 hover:text-yellow-400")}>
              ✨ Traits
            </.link>
            <.link navigate={~p"/admin/members"} class={"px-4 py-2 rounded-lg text-sm font-medium transition-colors duration-200 " <> if(@live_action == :members, do: "bg-yellow-600 text-gray-900", else: "text-gray-300 hover:bg-gray-700 hover:text-yellow-400")}>
              👥 Members
            </.link>
            <.link navigate={~p"/admin/rules"} class={"px-4 py-2 rounded-lg text-sm font-medium transition-colors duration-200 " <> if(@live_action == :rules, do: "bg-yellow-600 text-gray-900", else: "text-gray-300 hover:bg-gray-700 hover:text-yellow-400")}>
              📜 Rules
            </.link>
            <.link navigate={~p"/admin/audit"} class={"px-4 py-2 rounded-lg text-sm font-medium transition-colors duration-200 " <> if(@live_action == :audit, do: "bg-yellow-600 text-gray-900", else: "text-gray-300 hover:bg-gray-700 hover:text-yellow-400")}>
              📋 Audit Log
            </.link>
          </div>
        </div>

        <%= case @live_action do %>
          <% :index -> %>
            <%= render_dashboard(assigns) %>
          <% :houses -> %>
            <%= render_houses(assigns) %>
          <% :traits -> %>
            <%= render_traits(assigns) %>
          <% :members -> %>
            <%= render_members(assigns) %>
          <% :rules -> %>
            <%= render_rules(assigns) %>
          <% :audit -> %>
            <%= render_audit_log(assigns) %>
        <% end %>
      </div>
    </div>

    <%= if @show_modal do %>
      <%= render_modal(assigns) %>
    <% end %>
    """
  end

  defp render_dashboard(assigns) do
    ~H"""
    <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
      <.link navigate={~p"/admin/houses"} class="bg-gradient-to-br from-red-800/80 to-red-900/80 backdrop-blur-sm rounded-xl shadow-2xl border border-red-500/30 p-6 hover:from-red-700/80 hover:to-red-800/80 transition-all duration-200 transform hover:scale-105 cursor-pointer">
        <div class="flex items-center mb-4">
          <div class="text-4xl mr-4">🏠</div>
          <div>
            <h3 class="text-xl font-bold text-red-300">Houses</h3>
            <div class="text-3xl font-bold text-red-400"><%= @stats.total_houses %></div>
          </div>
        </div>
        <p class="text-red-200 text-sm">Total registered houses</p>
        <div class="mt-3 text-red-300 text-xs opacity-75 flex items-center">
          <span>Click to manage</span>
          <span class="ml-1">→</span>
        </div>
      </.link>

      <.link navigate={~p"/admin/members"} class="bg-gradient-to-br from-blue-800/80 to-blue-900/80 backdrop-blur-sm rounded-xl shadow-2xl border border-blue-500/30 p-6 hover:from-blue-700/80 hover:to-blue-800/80 transition-all duration-200 transform hover:scale-105 cursor-pointer">
        <div class="flex items-center mb-4">
          <div class="text-4xl mr-4">👥</div>
          <div>
            <h3 class="text-xl font-bold text-blue-300">Members</h3>
            <div class="text-3xl font-bold text-blue-400"><%= @stats.total_members %></div>
          </div>
        </div>
        <p class="text-blue-200 text-sm">Active community members</p>
        <div class="mt-3 text-blue-300 text-xs opacity-75 flex items-center">
          <span>Click to manage</span>
          <span class="ml-1">→</span>
        </div>
      </.link>

      <.link navigate={~p"/admin/traits"} class="bg-gradient-to-br from-purple-800/80 to-purple-900/80 backdrop-blur-sm rounded-xl shadow-2xl border border-purple-500/30 p-6 hover:from-purple-700/80 hover:to-purple-800/80 transition-all duration-200 transform hover:scale-105 cursor-pointer">
        <div class="flex items-center mb-4">
          <div class="text-4xl mr-4">✨</div>
          <div>
            <h3 class="text-xl font-bold text-purple-300">Traits</h3>
            <div class="text-3xl font-bold text-purple-400"><%= @stats.total_traits %></div>
          </div>
        </div>
        <p class="text-purple-200 text-sm">Recognizable qualities</p>
        <div class="mt-3 text-purple-300 text-xs opacity-75 flex items-center">
          <span>Click to manage</span>
          <span class="ml-1">→</span>
        </div>
      </.link>

      <.link navigate={~p"/admin/audit"} class="bg-gradient-to-br from-green-800/80 to-green-900/80 backdrop-blur-sm rounded-xl shadow-2xl border border-green-500/30 p-6 hover:from-green-700/80 hover:to-green-800/80 transition-all duration-200 transform hover:scale-105 cursor-pointer">
        <div class="flex items-center mb-4">
          <div class="text-4xl mr-4">🏆</div>
          <div>
            <h3 class="text-xl font-bold text-green-300">Total Awards</h3>
            <div class="text-3xl font-bold text-green-400"><%= @stats.total_awards %></div>
          </div>
        </div>
        <p class="text-green-200 text-sm">Points awarded to date</p>
        <div class="mt-3 text-green-300 text-xs opacity-75 flex items-center">
          <span>Click to view audit log</span>
          <span class="ml-1">→</span>
        </div>
      </.link>

      <.link navigate={~p"/admin/rules"} class="bg-gradient-to-br from-yellow-800/80 to-yellow-900/80 backdrop-blur-sm rounded-xl shadow-2xl border border-yellow-500/30 p-6 hover:from-yellow-700/80 hover:to-yellow-800/80 transition-all duration-200 transform hover:scale-105 cursor-pointer">
        <div class="flex items-center mb-4">
          <div class="text-4xl mr-4">⭐</div>
          <div>
            <h3 class="text-xl font-bold text-yellow-300">Total Points</h3>
            <div class="text-3xl font-bold text-yellow-400"><%= @stats.total_points %></div>
          </div>
        </div>
        <p class="text-yellow-200 text-sm">Points in circulation</p>
        <div class="mt-3 text-yellow-300 text-xs opacity-75 flex items-center">
          <span>Click to configure rules</span>
          <span class="ml-1">→</span>
        </div>
      </.link>

      <.link navigate={~p"/award"} class="bg-gradient-to-br from-indigo-800/80 to-indigo-900/80 backdrop-blur-sm rounded-xl shadow-2xl border border-indigo-500/30 p-6 hover:from-indigo-700/80 hover:to-indigo-800/80 transition-all duration-200 transform hover:scale-105 cursor-pointer">
        <div class="flex items-center mb-4">
          <div class="text-4xl mr-4">📈</div>
          <div>
            <h3 class="text-xl font-bold text-indigo-300">This Week</h3>
            <div class="text-3xl font-bold text-indigo-400"><%= @stats.weekly_awards %></div>
          </div>
        </div>
        <p class="text-indigo-200 text-sm">Awards this week</p>
        <div class="mt-3 text-indigo-300 text-xs opacity-75 flex items-center">
          <span>Click to award points</span>
          <span class="ml-1">→</span>
        </div>
      </.link>
    </div>
    """
  end

  defp render_houses(assigns) do
    ~H"""
    <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-yellow-600/30">
      <div class="p-8">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-3xl font-bold text-yellow-400">🏠 House Management</h2>
          <button phx-click="new_house" class="bg-gradient-to-r from-yellow-600 to-yellow-500 hover:from-yellow-500 hover:to-yellow-400 text-gray-900 font-bold py-2 px-4 rounded-lg transition-all duration-200 shadow-lg hover:shadow-xl">
            ➕ Add New House
          </button>
        </div>

        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr class="bg-gray-700">
                <th class="text-yellow-400">Name</th>
                <th class="text-yellow-400">Color</th>
                <th class="text-yellow-400">Crest</th>
                <th class="text-yellow-400">Members</th>
                <th class="text-yellow-400">Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for house <- @houses do %>
                <tr class="hover:bg-gray-700/50">
                  <td class="text-gray-300 font-semibold"><%= house.name %></td>
                  <td>
                    <div class="flex items-center gap-2">
                      <div class="w-6 h-6 rounded-full" style={"background-color: #{house.color}"}></div>
                      <span class="text-gray-300"><%= house.color %></span>
                    </div>
                  </td>
                  <td class="text-gray-300"><%= house.crest_url %></td>
                  <td class="text-gray-300"><%= Directory.count_members_by_house(house.name) %></td>
                  <td>
                    <button phx-click="edit_house" phx-value-id={house.id} class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-1 px-3 rounded text-sm transition-colors duration-200">
                      Edit
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp render_traits(assigns) do
    ~H"""
    <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-purple-600/30">
      <div class="p-8">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-3xl font-bold text-purple-400">✨ Trait Management</h2>
          <button phx-click="new_trait" class="bg-gradient-to-r from-purple-600 to-purple-500 hover:from-purple-500 hover:to-purple-400 text-white font-bold py-2 px-4 rounded-lg transition-all duration-200 shadow-lg hover:shadow-xl">
            ➕ Add New Trait
          </button>
        </div>

        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr class="bg-gray-700">
                <th class="text-purple-400">Name</th>
                <th class="text-purple-400">Description</th>
                <th class="text-purple-400">House</th>
                <th class="text-purple-400">Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for trait <- @traits do %>
                <tr class="hover:bg-gray-700/50">
                  <td class="text-gray-300 font-semibold"><%= trait.name %></td>
                  <td class="text-gray-300"><%= trait.description %></td>
                  <td class="text-gray-300"><%= if trait.house, do: trait.house.name, else: "Universal" %></td>
                  <td>
                    <button phx-click="edit_trait" phx-value-id={trait.id} class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-1 px-3 rounded text-sm transition-colors duration-200">
                      Edit
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp render_members(assigns) do
    ~H"""
    <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-green-600/30">
      <div class="p-8">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-3xl font-bold text-green-400">👥 Member Management</h2>
        </div>

        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr class="bg-gray-700">
                <th class="text-green-400">Name</th>
                <th class="text-green-400">Email</th>
                <th class="text-green-400">House</th>
                <th class="text-green-400">Status</th>
                <th class="text-green-400">Last Sign In</th>
                <th class="text-green-400">Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for member <- @members do %>
                <tr class="hover:bg-gray-700/50">
                  <td class="text-gray-300 font-semibold"><%= member.name %></td>
                  <td class="text-gray-300"><%= member.email %></td>
                  <td>
                    <%= if member.house do %>
                      <span class="px-2 py-1 rounded text-sm font-medium" style={"background-color: #{member.house.color}20; color: #{member.house.color};"}>
                        <%= member.house.name %>
                      </span>
                    <% else %>
                      <span class="text-gray-500 italic">No House</span>
                    <% end %>
                  </td>
                  <td>
                    <span class={"px-2 py-1 rounded text-sm font-medium " <> if(member.is_active, do: "bg-green-800 text-green-300", else: "bg-red-800 text-red-300")}>
                      <%= if member.is_active, do: "Active", else: "Inactive" %>
                    </span>
                  </td>
                  <td class="text-gray-300"><%= if member.last_sign_in_at, do: format_datetime(member.last_sign_in_at), else: "Never" %></td>
                  <td>
                    <button phx-click="edit_member" phx-value-id={member.id} class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-1 px-3 rounded text-sm transition-colors duration-200">
                      Edit
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp render_rules(assigns) do
    ~H"""
    <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-yellow-600/30">
      <div class="p-8">
        <h2 class="text-3xl font-bold text-yellow-400 mb-6">📜 Rules Configuration</h2>

        <.form for={@form} phx-change="validate_rules" phx-submit="save_rules">
          <div class="grid md:grid-cols-2 gap-6">
            <div class="space-y-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text font-semibold text-gray-300">Max Points Per Giver Per Day</span>
                </label>
                <.input field={@form[:max_points_per_giver_per_day]} type="number" min="1" placeholder="Enter daily limit..." class="input-bordered bg-gray-700 text-gray-100" />
                <div class="label">
                  <span class="label-text-alt text-gray-400">How many points each person can award per day</span>
                </div>
              </div>

              <div class="form-control mt-6">
                <.button type="submit" disabled={!@form.source.valid?} class="bg-gradient-to-r from-yellow-600 to-yellow-500 hover:from-yellow-500 hover:to-yellow-400 disabled:from-gray-600 disabled:to-gray-500 text-gray-900 font-bold py-3 px-6 rounded-lg w-full transition-all duration-200 shadow-lg hover:shadow-xl disabled:cursor-not-allowed">
                  <%= if @current_rules, do: "Update Rules", else: "Create Rules" %>
                </.button>
              </div>
            </div>

            <div class="bg-gray-700/50 rounded-lg p-4">
              <h3 class="text-lg font-semibold text-yellow-300 mb-3">📊 Current Settings</h3>
              <%= if @current_rules do %>
                <div class="space-y-2">
                  <div class="flex justify-between">
                    <span class="text-gray-300">Daily Limit:</span>
                    <span class="text-yellow-400 font-bold"><%= @current_rules.max_points_per_giver_per_day %> points</span>
                  </div>
                  <div class="flex justify-between">
                    <span class="text-gray-300">Last Updated:</span>
                    <span class="text-gray-400"><%= format_datetime(@current_rules.updated_at) %></span>
                  </div>
                </div>
              <% else %>
                <p class="text-gray-400 italic">No rules configured yet.</p>
              <% end %>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp render_audit_log(assigns) do
    ~H"""
    <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-indigo-600/30">
      <div class="p-8">
        <h2 class="text-3xl font-bold text-indigo-400 mb-6">📋 Audit Log</h2>

        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr class="bg-gray-700">
                <th class="text-indigo-400">Timestamp</th>
                <th class="text-indigo-400">Action</th>
                <th class="text-indigo-400">Actor</th>
                <th class="text-indigo-400">Award ID</th>
                <th class="text-indigo-400">Details</th>
              </tr>
            </thead>
            <tbody>
              <%= for log <- @audit_logs do %>
                <tr class="hover:bg-gray-700/50">
                  <td class="text-gray-300"><%= format_datetime(log.inserted_at) %></td>
                  <td>
                    <span class={"px-2 py-1 rounded text-sm font-medium " <> action_badge_class(log.action)}>
                      <%= format_action(log.action) %>
                    </span>
                  </td>
                  <td class="text-gray-300"><%= if log.actor, do: log.actor.name, else: "System" %></td>
                  <td class="text-gray-300">#<%= log.award_id %></td>
                  <td class="text-gray-400 text-sm">
                    <%= if log.diff do %>
                      <details class="cursor-pointer">
                        <summary class="text-indigo-400 hover:text-indigo-300">View Changes</summary>
                        <pre class="text-xs mt-2 p-2 bg-gray-900 rounded"><%= inspect(log.diff, pretty: true) %></pre>
                      </details>
                    <% else %>
                      <span class="italic">No additional details</span>
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp render_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" phx-click="close_modal">
      <div class="bg-gray-800 rounded-xl shadow-2xl border border-yellow-600/30 p-6 max-w-lg w-full mx-4" phx-click="prevent_close">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-xl font-bold text-yellow-400">
            <%= cond do %>
              <% is_struct(@editing_item, House) && @editing_item.id -> %>Edit House
              <% is_struct(@editing_item, House) -> %>New House
              <% is_struct(@editing_item, Trait) && @editing_item.id -> %>Edit Trait
              <% is_struct(@editing_item, Trait) -> %>New Trait
              <% is_struct(@editing_item, Member) -> %>Edit Member
              <% true -> %>Edit Item
            <% end %>
          </h3>
          <button phx-click="close_modal" class="text-gray-400 hover:text-gray-200">
            ✕
          </button>
        </div>

        <%= cond do %>
          <% is_struct(@editing_item, House) -> %>
            <.form for={@form} phx-change="validate_house" phx-submit="save_house">
              <div class="space-y-4">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-gray-300">House Name</span>
                  </label>
                  <.input field={@form[:name]} type="text" placeholder="Enter house name..." class="input-bordered bg-gray-700 text-gray-100" />
                </div>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-gray-300">House Color (Hex)</span>
                  </label>
                  <.input field={@form[:color]} type="text" placeholder="#RRGGBB" class="input-bordered bg-gray-700 text-gray-100" />
                </div>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-gray-300">Crest URL</span>
                  </label>
                  <.input field={@form[:crest_url]} type="text" placeholder="Enter image URL..." class="input-bordered bg-gray-700 text-gray-100" />
                </div>

                <div class="flex gap-2 mt-6">
                  <.button type="submit" disabled={!@form.source.valid?} class="bg-gradient-to-r from-yellow-600 to-yellow-500 hover:from-yellow-500 hover:to-yellow-400 disabled:from-gray-600 disabled:to-gray-500 text-gray-900 font-bold py-2 px-4 rounded-lg flex-1 transition-all duration-200">
                    <%= if @editing_item.id, do: "Update", else: "Create" %>
                  </.button>
                  <button type="button" phx-click="close_modal" class="bg-gray-600 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded-lg transition-colors duration-200">
                    Cancel
                  </button>
                </div>
              </div>
            </.form>

          <% is_struct(@editing_item, Trait) -> %>
            <.form for={@form} phx-change="validate_trait" phx-submit="save_trait">
              <div class="space-y-4">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-gray-300">Trait Name</span>
                  </label>
                  <.input field={@form[:name]} type="text" placeholder="Enter trait name..." class="input-bordered bg-gray-700 text-gray-100" />
                </div>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-gray-300">Description</span>
                  </label>
                  <.input field={@form[:description]} type="textarea" rows="3" placeholder="Describe the trait..." class="textarea-bordered bg-gray-700 text-gray-100" />
                </div>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-gray-300">Associated House (Optional)</span>
                  </label>
                  <.input field={@form[:house_id]} type="select" options={@houses_for_select} prompt="Universal trait" class="select-bordered bg-gray-700 text-gray-100" />
                </div>

                <div class="flex gap-2 mt-6">
                  <.button type="submit" disabled={!@form.source.valid?} class="bg-gradient-to-r from-purple-600 to-purple-500 hover:from-purple-500 hover:to-purple-400 disabled:from-gray-600 disabled:to-gray-500 text-white font-bold py-2 px-4 rounded-lg flex-1 transition-all duration-200">
                    <%= if @editing_item.id, do: "Update", else: "Create" %>
                  </.button>
                  <button type="button" phx-click="close_modal" class="bg-gray-600 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded-lg transition-colors duration-200">
                    Cancel
                  </button>
                </div>
              </div>
            </.form>

          <% is_struct(@editing_item, Member) -> %>
            <.form for={@form} phx-change="validate_member" phx-submit="save_member">
              <div class="space-y-4">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-gray-300">Name</span>
                  </label>
                  <.input field={@form[:name]} type="text" placeholder="Enter member name..." class="input-bordered bg-gray-700 text-gray-100" />
                </div>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-gray-300">Email</span>
                  </label>
                  <.input field={@form[:email]} type="email" placeholder="Enter email..." class="input-bordered bg-gray-700 text-gray-100" />
                </div>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-gray-300">First Name</span>
                  </label>
                  <.input field={@form[:first_name]} type="text" placeholder="First name..." class="input-bordered bg-gray-700 text-gray-100" />
                </div>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-gray-300">Last Name</span>
                  </label>
                  <.input field={@form[:last_name]} type="text" placeholder="Last name..." class="input-bordered bg-gray-700 text-gray-100" />
                </div>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-gray-300">House</span>
                  </label>
                  <.input field={@form[:house_id]} type="select" options={@houses_for_select} prompt="Select house..." class="select-bordered bg-gray-700 text-gray-100" />
                </div>

                <div class="form-control">
                  <label class="cursor-pointer label">
                    <span class="label-text text-gray-300">Active</span>
                    <.input field={@form[:is_active]} type="checkbox" class="checkbox checkbox-primary" />
                  </label>
                </div>

                <div class="flex gap-2 mt-6">
                  <.button type="submit" disabled={!@form.source.valid?} class="bg-gradient-to-r from-green-600 to-green-500 hover:from-green-500 hover:to-green-400 disabled:from-gray-600 disabled:to-gray-500 text-white font-bold py-2 px-4 rounded-lg flex-1 transition-all duration-200">
                    Update
                  </.button>
                  <button type="button" phx-click="close_modal" class="bg-gray-600 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded-lg transition-colors duration-200">
                    Cancel
                  </button>
                </div>
              </div>
            </.form>
        <% end %>
      </div>
    </div>
    """
  end

  # Helper functions
  defp get_dashboard_stats do
    total_houses = Repo.aggregate(House, :count, :id)
    total_members = Repo.aggregate(Member, :count, :id)
    total_traits = Repo.aggregate(Trait, :count, :id)
    total_awards = Repo.aggregate(Award, :count, :id)
    total_points = Repo.aggregate(from(a in Award, where: is_nil(a.deleted_at)), :sum, :points) || 0

    # Weekly awards
    week_start = Date.beginning_of_week(Date.utc_today())
    week_start_dt = DateTime.new!(week_start, ~T[00:00:00])

    weekly_awards = Repo.aggregate(
      from(a in Award, where: a.inserted_at >= ^week_start_dt and is_nil(a.deleted_at)),
      :count, :id
    )

    %{
      total_houses: total_houses,
      total_members: total_members,
      total_traits: total_traits,
      total_awards: total_awards,
      total_points: total_points,
      weekly_awards: weekly_awards
    }
  end

  defp houses_for_select do
    Directory.list_houses()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp rules_form(rules) do
    to_form(Recognition.change_rule(rules || %Rule{}, %{}))
  end

  defp format_datetime(datetime) do
    datetime
    |> DateTime.shift_zone!("Etc/UTC")
    |> Calendar.strftime("%m/%d/%Y at %I:%M %p")
  end

  defp action_badge_class("award_created"), do: "bg-green-800 text-green-300"
  defp action_badge_class("award_revoked"), do: "bg-red-800 text-red-300"
  defp action_badge_class("award_updated"), do: "bg-blue-800 text-blue-300"
  defp action_badge_class(_), do: "bg-gray-800 text-gray-300"

  defp format_action("award_created"), do: "✅ Created"
  defp format_action("award_revoked"), do: "❌ Revoked"
  defp format_action("award_updated"), do: "✏️ Updated"
  defp format_action(action), do: action
end