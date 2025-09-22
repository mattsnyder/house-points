defmodule HousePointsWeb.HouseSelectionLive do
  use HousePointsWeb, :live_view

  alias HousePoints.{Auth, Directory}

  on_mount {HousePointsWeb.AuthPlug, :require_house_selection}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    houses = Directory.list_houses()

    socket =
      socket
      |> assign(:houses, houses)
      |> assign(:selected_house, nil)
      |> assign(:page_title, "Choose Your House")

    {:ok, socket}
  end

  @impl true
  def handle_event("select_house", %{"house_id" => house_id}, socket) do
    house_id = String.to_integer(house_id)
    selected_house = Enum.find(socket.assigns.houses, &(&1.id == house_id))

    socket = assign(socket, :selected_house, selected_house)
    {:noreply, socket}
  end

  @impl true
  def handle_event("confirm_house", _params, socket) do
    case socket.assigns.selected_house do
      nil ->
        socket = put_flash(socket, :error, "Please select a house first!")
        {:noreply, socket}

      house ->
        case Auth.assign_house_to_member(socket.assigns.current_user, house.id) do
          {:ok, updated_member} ->
            socket =
              socket
              |> assign(:current_user, updated_member)
              |> put_flash(:info, "🎉 Welcome to #{house.name}! You're ready to start earning points.")
              |> push_navigate(to: ~p"/leaderboard")

            {:noreply, socket}

          {:error, _changeset} ->
            socket = put_flash(socket, :error, "Failed to assign house. Please try again.")
            {:noreply, socket}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-purple-900 via-indigo-900 to-blue-900">
      <div class="container mx-auto px-4 py-8">
        <div class="max-w-4xl mx-auto">
          <!-- Header -->
          <div class="text-center mb-12">
            <div class="text-6xl mb-4">🎓</div>
            <h1 class="text-4xl font-bold text-white mb-4">The Sorting Hat Awaits</h1>
            <p class="text-xl text-gray-200 mb-2">
              Hello, <strong><%= @current_user.name %></strong>!
            </p>
            <p class="text-lg text-gray-300">
              Choose the house that best represents your values and working style.
            </p>
          </div>

          <!-- House Selection -->
          <div class="grid md:grid-cols-2 gap-6 mb-8">
            <%= for house <- @houses do %>
              <div class={"card cursor-pointer transition-all duration-300 #{house_card_classes(house, @selected_house)}"}
                   phx-click="select_house"
                   phx-value-house_id={house.id}>
                <div class="card-body">
                  <div class="flex items-center justify-between mb-4">
                    <h2 class="card-title text-2xl text-white"><%= house.name %></h2>
                    <%= if @selected_house && @selected_house.id == house.id do %>
                      <div class="badge badge-accent">Selected</div>
                    <% end %>
                  </div>

                  <div class="text-4xl mb-4 text-center">
                    <%= house_emoji(house.name) %>
                  </div>

                  <div class="space-y-2 mb-4">
                    <%= for trait <- house_traits(house.name) do %>
                      <div class="flex items-center space-x-2">
                        <span class="text-lg"><%= trait.emoji %></span>
                        <div>
                          <div class="font-semibold text-white"><%= trait.name %></div>
                          <div class="text-sm text-gray-300"><%= trait.description %></div>
                        </div>
                      </div>
                    <% end %>
                  </div>

                  <div class="text-sm text-gray-400 italic text-center">
                    "<%= house_quote(house.name) %>"
                  </div>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Confirmation Button -->
          <%= if @selected_house do %>
            <div class="text-center">
              <div class="card bg-base-100 shadow-xl max-w-md mx-auto">
                <div class="card-body">
                  <h3 class="card-title justify-center">Ready to join <%= @selected_house.name %>?</h3>
                  <p class="text-center text-base-content/70 mb-4">
                    You'll be able to award and receive points for demonstrating <%= @selected_house.name %> traits.
                  </p>
                  <button
                    phx-click="confirm_house"
                    class="btn btn-primary btn-lg w-full"
                  >
                    🏠 Join <%= @selected_house.name %>
                  </button>
                </div>
              </div>
            </div>
          <% else %>
            <div class="text-center">
              <div class="card bg-base-100/10 border border-white/20">
                <div class="card-body">
                  <p class="text-white/70">Click on a house above to learn more and make your selection.</p>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end


  defp house_card_classes(house, selected_house) do
    base_classes = "shadow-xl border-2 transition-all duration-300 hover:scale-105"

    color_classes = case house.name do
      "Gryffindor" -> "bg-red-900 border-red-700 hover:border-red-500"
      "Hufflepuff" -> "bg-yellow-700 border-yellow-600 hover:border-yellow-400"
      "Ravenclaw" -> "bg-blue-900 border-blue-700 hover:border-blue-500"
      "Slytherin" -> "bg-green-900 border-green-700 hover:border-green-500"
      _ -> "bg-gray-800 border-gray-600"
    end

    selected_classes = if selected_house && selected_house.id == house.id do
      "ring-4 ring-accent scale-105"
    else
      ""
    end

    "#{base_classes} #{color_classes} #{selected_classes}"
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

  defp house_traits(house_name) do
    case house_name do
      "Gryffindor" -> [
        %{emoji: "⚡", name: "Courage", description: "Bravery in challenging situations"},
        %{emoji: "🚀", name: "Initiative", description: "Taking action and leading"},
        %{emoji: "🔥", name: "Boldness", description: "Confident decisions and risks"}
      ]
      "Hufflepuff" -> [
        %{emoji: "🤝", name: "Teamwork", description: "Collaboration and support"},
        %{emoji: "💛", name: "Loyalty", description: "Commitment and reliability"},
        %{emoji: "🛡️", name: "Steadfastness", description: "Consistency and perseverance"}
      ]
      "Ravenclaw" -> [
        %{emoji: "🔍", name: "Curiosity", description: "Asking thoughtful questions"},
        %{emoji: "💡", name: "Insight", description: "Valuable perspectives"},
        %{emoji: "🧠", name: "Cleverness", description: "Creative problem solving"}
      ]
      "Slytherin" -> [
        %{emoji: "🎯", name: "Ambition", description: "High goals and strategy"},
        %{emoji: "⚙️", name: "Resourcefulness", description: "Using opportunities well"},
        %{emoji: "💪", name: "Drive", description: "Determination and persistence"}
      ]
      _ -> []
    end
  end

  defp house_quote(house_name) do
    case house_name do
      "Gryffindor" -> "Where dwell the brave at heart"
      "Hufflepuff" -> "Where they are just and loyal"
      "Ravenclaw" -> "Where those of wit and learning will always find their kind"
      "Slytherin" -> "Where you'll make your real friends"
      _ -> ""
    end
  end
end