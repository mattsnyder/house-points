defmodule HousePointsWeb.RoomOfRequirementLive do
  use HousePointsWeb, :live_view

  alias HousePoints.{Recognition, Directory}
  alias HousePoints.Recognition.Award

  on_mount {HousePointsWeb.AuthPlug, :require_underdog}

  @daily_curse_limit -300

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    members = Directory.list_members()
    curse_points_used = Recognition.daily_curse_points_used(current_user)
    remaining = @daily_curse_limit - curse_points_used

    changeset = Award.curse_form_changeset(%Award{}, %{})

    socket =
      socket
      |> assign(:page_title, "The Room of Requirement")
      |> assign(:members, members)
      |> assign(:changeset, changeset)
      |> assign(:form, to_form(changeset, as: :curse))
      |> assign(:curse_points_used, curse_points_used)
      |> assign(:remaining_curse_points, remaining)
      |> assign(:daily_curse_limit, @daily_curse_limit)
      |> assign(:cast_success, false)
      |> assign(:flicker, true)

    if connected?(socket) do
      Process.send_after(self(), :stop_flicker, 2000)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:stop_flicker, socket) do
    {:noreply, assign(socket, :flicker, false)}
  end

  @impl true
  def handle_event("validate", %{"curse" => curse_params}, socket) do
    changeset =
      %Award{}
      |> Award.curse_form_changeset(curse_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset, as: :curse))}
  end

  @impl true
  def handle_event("cast_hex", %{"curse" => curse_params}, socket) do
    current_user = socket.assigns.current_user

    points =
      case Integer.parse(curse_params["points"] || "0") do
        {num, _} -> num
        _ -> 0
      end

    # Ensure points are negative
    points = if points > 0, do: -points, else: points

    receiver_id =
      case Integer.parse(curse_params["receiver_id"] || "") do
        {id, _} -> id
        _ -> nil
      end

    receiver = if receiver_id, do: Directory.get_member!(receiver_id), else: nil

    if receiver do
      case Recognition.cast_curse(current_user, receiver, points, curse_params["reason"]) do
        {:ok, award} ->
          curse_points_used = Recognition.daily_curse_points_used(current_user)
          remaining = @daily_curse_limit - curse_points_used

          changeset = Award.curse_form_changeset(%Award{}, %{})
          scapegoat_name = award.apparent_giver.name

          socket =
            socket
            |> assign(:changeset, changeset)
            |> assign(:form, to_form(changeset, as: :curse))
            |> assign(:curse_points_used, curse_points_used)
            |> assign(:remaining_curse_points, remaining)
            |> assign(:cast_success, true)
            |> put_flash(:info, "The deed is done. #{scapegoat_name} will take the blame.")

          {:noreply, socket}

        {:error, :cannot_curse_own_house} ->
          {:noreply, put_flash(socket, :error, "You cannot hex your own house.")}

        {:error, :daily_curse_limit_exceeded} ->
          {:noreply, put_flash(socket, :error, "Your dark magic is spent for today.")}

        {:error, changeset} ->
          {:noreply,
           socket
           |> assign(:changeset, changeset)
           |> assign(:form, to_form(changeset, as: :curse))}
      end
    else
      {:noreply, put_flash(socket, :error, "You must select a target.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={"min-h-screen bg-gradient-to-b from-gray-950 via-gray-900 to-black relative overflow-hidden " <> if(@flicker, do: "animate-flicker", else: "")}>
      <!-- Ambient particles -->
      <div class="absolute inset-0 pointer-events-none">
        <div class="absolute top-20 left-10 w-1 h-1 bg-blue-400 rounded-full animate-pulse opacity-30"></div>
        <div class="absolute top-40 right-20 w-1 h-1 bg-purple-400 rounded-full animate-pulse opacity-20" style="animation-delay: 0.5s"></div>
        <div class="absolute top-60 left-1/3 w-1 h-1 bg-indigo-400 rounded-full animate-pulse opacity-25" style="animation-delay: 1s"></div>
        <div class="absolute bottom-40 right-1/4 w-1 h-1 bg-blue-300 rounded-full animate-pulse opacity-20" style="animation-delay: 1.5s"></div>
        <div class="absolute bottom-20 left-1/4 w-1 h-1 bg-purple-300 rounded-full animate-pulse opacity-30" style="animation-delay: 2s"></div>
      </div>

      <div class="container mx-auto px-4 py-12 max-w-2xl relative z-10">
        <!-- Header -->
        <div class="text-center mb-10">
          <div class="text-5xl mb-4 opacity-80">🚪</div>
          <h1 class="text-4xl font-bold mb-3 text-transparent bg-clip-text bg-gradient-to-r from-blue-300 via-indigo-300 to-purple-300">
            The Room of Requirement
          </h1>
          <p class="text-lg text-gray-500 italic">"I need somewhere to settle the score..."</p>
        </div>

        <!-- Curse Gauge -->
        <div class="mb-8 bg-gray-900/80 backdrop-blur-sm rounded-xl border border-indigo-900/50 p-4">
          <div class="flex justify-between items-center mb-2">
            <span class="text-sm text-gray-500 uppercase tracking-wider">Dark Energy Remaining</span>
            <span class="text-sm font-mono text-indigo-400"><%= abs(@remaining_curse_points) %> / <%= abs(@daily_curse_limit) %></span>
          </div>
          <div class="w-full bg-gray-800 rounded-full h-2">
            <div
              class="bg-gradient-to-r from-indigo-600 to-purple-600 h-2 rounded-full transition-all duration-500"
              style={"width: #{min(100, abs(@remaining_curse_points) / abs(@daily_curse_limit) * 100)}%"}
            >
            </div>
          </div>
        </div>

        <!-- Curse Form -->
        <div class="bg-gray-900/80 backdrop-blur-sm rounded-xl border border-indigo-900/50 shadow-2xl shadow-indigo-950/50">
          <div class="p-8">
            <.form for={@form} phx-change="validate" phx-submit="cast_hex">
              <div class="space-y-6">
                <!-- Target Member -->
                <div>
                  <label class="block text-sm font-medium text-gray-400 mb-2 uppercase tracking-wider">
                    Target
                  </label>
                  <.input
                    field={@form[:receiver_id]}
                    type="select"
                    options={victim_options(@members, @current_user)}
                    prompt="Select your victim..."
                  />
                </div>

                <!-- Curse Intensity -->
                <div>
                  <label class="block text-sm font-medium text-gray-400 mb-2 uppercase tracking-wider">
                    Curse Intensity <span class="text-gray-600 normal-case">(1 to 300 points)</span>
                  </label>
                  <.input
                    field={@form[:points]}
                    type="number"
                    min="-300"
                    max="-1"
                    placeholder="-50"
                  />
                  <p class="mt-1 text-xs text-gray-600">Enter a negative number (e.g. -50)</p>
                </div>

                <!-- Incantation -->
                <div>
                  <label class="block text-sm font-medium text-gray-400 mb-2 uppercase tracking-wider">
                    Incantation <span class="text-gray-600 normal-case">(your reason)</span>
                  </label>
                  <.input
                    field={@form[:reason]}
                    type="textarea"
                    rows="3"
                    placeholder="Speak your curse..."
                  />
                </div>

                <!-- Submit -->
                <div class="pt-2">
                  <.button
                    type="submit"
                    disabled={!@changeset.valid? || @remaining_curse_points >= 0}
                    class="w-full bg-gradient-to-r from-indigo-800 to-purple-800 hover:from-indigo-700 hover:to-purple-700 disabled:from-gray-800 disabled:to-gray-800 text-indigo-200 disabled:text-gray-600 font-bold py-3 px-6 rounded-lg transition-all duration-300 shadow-lg shadow-indigo-950/50 hover:shadow-indigo-900/50 disabled:shadow-none disabled:cursor-not-allowed border border-indigo-700/30 disabled:border-gray-800"
                  >
                    Cast Hex
                  </.button>
                </div>
              </div>
            </.form>
          </div>
        </div>

        <!-- Footer -->
        <div class="text-center mt-8">
          <p class="text-xs text-gray-700">"Wit beyond measure is man's greatest treasure."</p>
        </div>
      </div>
    </div>

    <style>
      @keyframes flicker {
        0%, 100% { opacity: 1; }
        10% { opacity: 0.8; }
        20% { opacity: 1; }
        30% { opacity: 0.6; }
        40% { opacity: 1; }
        50% { opacity: 0.9; }
        60% { opacity: 0.4; }
        70% { opacity: 1; }
        80% { opacity: 0.7; }
        90% { opacity: 1; }
      }
      .animate-flicker {
        animation: flicker 2s ease-in-out;
      }
    </style>
    """
  end

  defp victim_options(members, current_user) do
    members
    |> Enum.reject(&(&1.house_id == current_user.house_id))
    |> Enum.sort_by(& &1.name)
    |> Enum.map(fn member ->
      house_name = if member.house, do: member.house.name, else: "No House"
      {"#{member.name} (#{house_name})", member.id}
    end)
  end
end
