defmodule HousePointsWeb.AwardLive do
  use HousePointsWeb, :live_view
  import Ecto.Query

  alias HousePoints.{Recognition, Directory}
  alias HousePoints.Recognition.Award

  on_mount {HousePointsWeb.AuthPlug, :require_authenticated_user}

  @impl true
  def mount(_params, _session, socket) do
    changeset = Award.form_changeset(%Award{}, %{})
    current_user = socket.assigns.current_user

    daily_points_given = get_daily_points_given(current_user)
    daily_limit = get_daily_limit()
    remaining_points = daily_limit - daily_points_given

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:form, to_form(changeset))
      |> assign(:members, Directory.list_members())
      |> assign(:traits, Directory.list_traits())
      |> assign(:daily_points_given, daily_points_given)
      |> assign(:daily_limit, daily_limit)
      |> assign(:remaining_points, remaining_points)
      |> assign(:show_limit_warning, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"award" => award_params}, socket) do
    # Add current user as giver if not set
    award_params =
      if socket.assigns.current_user do
        Map.put_new(award_params, "giver_id", to_string(socket.assigns.current_user.id))
      else
        award_params
      end

    changeset =
      %Award{}
      |> Award.form_changeset(award_params)
      |> Map.put(:action, :validate)

    # Debug: Log changeset state
    IO.puts("=== VALIDATION DEBUG ===")
    IO.puts("Award params: #{inspect(award_params)}")
    IO.puts("Changeset valid?: #{changeset.valid?}")
    IO.puts("Changeset errors: #{inspect(changeset.errors)}")

    # Check daily limit warning
    points = case Integer.parse(award_params["points"] || "0") do
      {num, _} -> num
      _ -> 0
    end

    remaining_points = socket.assigns.daily_limit - socket.assigns.daily_points_given
    show_limit_warning = points > remaining_points

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:form, to_form(changeset))
      |> assign(:show_limit_warning, show_limit_warning)
      |> assign(:remaining_points, remaining_points)

    {:noreply, socket}
  end

  @impl true
  def handle_event("quick_award", %{"trait" => trait_name, "points" => points}, socket) do
    trait = Enum.find(socket.assigns.traits, &(&1.name == trait_name))

    if trait && socket.assigns.current_user do
      award_params = %{
        "giver_id" => to_string(socket.assigns.current_user.id),
        "trait_id" => to_string(trait.id),
        "points" => to_string(points),
        "reason" => get_quick_reason(trait_name)
      }

      changeset = Award.form_changeset(%Award{}, award_params)

      socket =
        socket
        |> assign(:changeset, changeset)
        |> assign(:form, to_form(changeset))
        |> assign(:quick_award_selected, trait_name)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save", %{"award" => award_params}, socket) do
    # Add current user as giver
    award_params =
      if socket.assigns.current_user do
        Map.put(award_params, "giver_id", to_string(socket.assigns.current_user.id))
      else
        award_params
      end

    case create_award(award_params) do
      {:ok, award} ->
        socket =
          socket
          |> put_flash(:info, "🎉 Award created successfully! #{award.points} points awarded.")
          |> push_navigate(to: ~p"/leaderboard")

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:changeset, changeset)
          |> assign(:form, to_form(changeset))

        {:noreply, socket}

      {:error, :self_award_not_allowed} ->
        socket = put_flash(socket, :error, "❌ You cannot award points to yourself!")
        {:noreply, socket}

      {:error, :daily_limit_exceeded} ->
        socket = put_flash(socket, :error, "⚠️ Daily point limit exceeded! You can only give #{socket.assigns.daily_limit} points per day.")
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-indigo-900 via-purple-900 to-gray-900">
      <div class="container mx-auto px-4 py-8 max-w-4xl">
        <div class="text-center mb-8">
          <h1 class="text-5xl font-bold mb-4 text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 via-yellow-300 to-yellow-500">
            Award House Points
          </h1>
          <%= if @current_user do %>
            <p class="text-xl text-gray-300 mb-4">Greetings, <strong class="text-yellow-400"><%= @current_user.name %></strong>!</p>
            <div class="bg-gray-800/60 backdrop-blur-sm rounded-lg px-4 py-2 inline-block border border-yellow-600/30">
              <span class="text-yellow-300"><%= Map.get(assigns, :remaining_points, @daily_limit - @daily_points_given) %> / <%= @daily_limit %> points remaining today</span>
            </div>
          <% end %>
          <p class="text-lg text-gray-400 italic mt-4">"Help will always be given at Hogwarts to those who ask for it."</p>
        </div>

      <div class="grid lg:grid-cols-2 gap-8">
        <!-- Award Form -->
        <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-yellow-600/30">
          <div class="p-8">
            <h2 class="text-2xl font-bold mb-6 text-yellow-400 text-center">Award House Points</h2>

            <.form for={@form} phx-change="validate" phx-submit="save">
              <%= if @current_user do %>
                <input type="hidden" name="award[giver_id]" value={@current_user.id} />
                <div class="form-control mb-4">
                  <label class="label">
                    <span class="label-text font-semibold text-gray-300">From: <span class="text-yellow-400"><%= @current_user.name %></span></span>
                  </label>
                </div>
              <% else %>
                <div class="form-control mb-4">
                  <label class="label">
                    <span class="label-text">Giver</span>
                  </label>
                  <.input field={@form[:giver_id]} type="select" options={member_options(@members)} prompt="Select giver..." />
                </div>
              <% end %>

              <div class="form-control mb-4">
                <label class="label">
                  <span class="label-text font-semibold text-gray-300">To: <span class="text-red-400">*</span></span>
                </label>
                <.input field={@form[:receiver_id]} type="select" options={receiver_options(@members, @current_user)} prompt="Select who you're recognizing..." />
              </div>

              <div class="form-control mb-4">
                <label class="label">
                  <span class="label-text font-semibold text-gray-300">For demonstrating: <span class="text-red-400">*</span></span>
                </label>
                <.input field={@form[:trait_id]} type="select" options={trait_options(@traits)} prompt="Select a trait..." />
              </div>

              <div class="form-control mb-4">
                <label class="label">
                  <span class="label-text font-semibold text-gray-300">Points (1-50) <span class="text-red-400">*</span></span>
                  <%= if assigns[:show_limit_warning] && @show_limit_warning do %>
                    <span class="label-text-alt text-yellow-400">⚠️ Exceeds daily limit!</span>
                  <% end %>
                </label>
                <.input field={@form[:points]} type="number" min="1" max="50" placeholder="How many points?" />
              </div>

              <div class="form-control mb-6">
                <label class="label">
                  <span class="label-text font-semibold text-gray-300">Why? <span class="text-red-400">*</span></span>
                  <span class="label-text-alt text-gray-400">Be specific about what they did!</span>
                </label>
                <.input field={@form[:reason]} type="textarea" rows="3" placeholder="Describe what they did that exemplified this trait..." />
              </div>

              <div class="form-control">
                <.button type="submit" disabled={!@changeset.valid? || (assigns[:show_limit_warning] && @show_limit_warning)} class="bg-gradient-to-r from-yellow-600 to-yellow-500 hover:from-yellow-500 hover:to-yellow-400 disabled:from-gray-600 disabled:to-gray-500 text-gray-900 font-bold py-3 px-6 rounded-lg w-full transition-all duration-200 shadow-lg hover:shadow-xl disabled:cursor-not-allowed">
                  Award Points
                </.button>
              </div>
            </.form>
          </div>
        </div>

        <!-- Quick Awards -->
        <div class="space-y-6">
          <div class="bg-gray-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-purple-600/30">
            <div class="p-8">
              <h2 class="text-2xl font-bold mb-4 text-purple-400 text-center">Quick Awards</h2>
              <p class="text-sm text-gray-300 mb-6 text-center">Award common traits with a single click:</p>

              <div class="grid grid-cols-1 gap-3">
                <%= for {letter, trait, points, description} <- quick_award_options() do %>
                  <button
                    phx-click="quick_award"
                    phx-value-trait={trait}
                    phx-value-points={points}
                    class={"btn btn-outline text-left justify-start #{if assigns[:quick_award_selected] == trait, do: "btn-active"}"}
                  >
                    <div class="w-10 h-10 mr-3 bg-purple-600 rounded-full flex items-center justify-center text-white font-bold">
                      <%= letter %>
                    </div>
                    <div class="text-left">
                      <div class="font-semibold"><%= trait %> (<%= points %>pts)</div>
                      <div class="text-xs opacity-70"><%= description %></div>
                    </div>
                  </button>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Magical Progress -->
          <%= if @current_user do %>
            <div class="bg-gradient-to-br from-indigo-800/80 to-purple-800/80 backdrop-blur-sm rounded-xl shadow-2xl border border-indigo-500/30">
              <div class="p-6">
                <h3 class="text-xl font-bold text-indigo-300 text-center mb-4">Your Daily Progress</h3>
                <div class="space-y-4">
                  <div class="text-center">
                    <div class="text-indigo-200 text-sm uppercase tracking-wide mb-1">Points Awarded Today</div>
                    <div class="text-3xl font-bold text-indigo-400"><%= @daily_points_given %></div>
                  </div>
                  <div class="text-center">
                    <div class="text-purple-200 text-sm uppercase tracking-wide mb-1">Points Remaining</div>
                    <div class="text-3xl font-bold text-purple-400"><%= Map.get(assigns, :remaining_points, @daily_limit - @daily_points_given) %></div>
                  </div>
                  <div class="w-full bg-gray-700 rounded-full h-3 mt-4">
                    <div class="bg-gradient-to-r from-indigo-500 to-purple-500 h-3 rounded-full transition-all duration-300" style={"width: #{(@daily_points_given / @daily_limit * 100)}%"}></div>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        </div>
      </div>
    </div>
    """
  end

  defp create_award(award_params) do
    with {:ok, giver} <- get_member(award_params["giver_id"]),
         {:ok, receiver} <- get_member(award_params["receiver_id"]),
         {:ok, trait} <- get_trait(award_params["trait_id"]) do
      Recognition.award_points(
        giver,
        receiver,
        trait,
        String.to_integer(award_params["points"] || "0"),
        award_params["reason"]
      )
    end
  end

  defp get_member(nil), do: {:error, :member_not_found}
  defp get_member(id), do: {:ok, Directory.get_member!(id)}

  defp get_trait(nil), do: {:error, :trait_not_found}
  defp get_trait(id), do: {:ok, Directory.get_trait!(id)}

  defp get_daily_points_given(nil), do: 0
  defp get_daily_points_given(user) do
    today = Date.utc_today()
    start_of_day = DateTime.new!(today, ~T[00:00:00])

    from(a in Award,
      where: a.giver_id == ^user.id and
             a.inserted_at >= ^start_of_day and
             is_nil(a.deleted_at),
      select: sum(a.points)
    )
    |> HousePoints.Repo.one() || 0
  end

  defp get_daily_limit do
    case Recognition.current_rules() do
      nil -> 30
      rules -> rules.max_points_per_giver_per_day
    end
  end

  defp get_quick_reason(trait_name) do
    case trait_name do
      "Courage" -> "Showed courage and bravery in a challenging situation"
      "Initiative" -> "Took initiative and led by example"
      "Boldness" -> "Made bold decisions and took calculated risks"
      "Teamwork" -> "Demonstrated excellent teamwork and collaboration"
      "Loyalty" -> "Showed loyalty and commitment to the team"
      "Steadfastness" -> "Maintained consistency and perseverance"
      "Curiosity" -> "Asked thoughtful questions and sought to understand"
      "Insight" -> "Provided valuable insights and perspectives"
      "Cleverness" -> "Found creative and intelligent solutions"
      "Ambition" -> "Set high goals and worked strategically"
      "Resourcefulness" -> "Made excellent use of available resources"
      "Drive" -> "Showed determination and persistence"
      _ -> "Excellent demonstration of #{trait_name}"
    end
  end

  defp quick_award_options do
    [
      {"C", "Courage", 10, "For bravery in challenging situations"},
      {"T", "Teamwork", 8, "For excellent collaboration"},
      {"L", "Cleverness", 7, "For creative problem solving"},
      {"I", "Initiative", 9, "For taking action and leading"},
      {"Y", "Loyalty", 6, "For commitment and reliability"},
      {"U", "Curiosity", 5, "For asking great questions"},
      {"D", "Drive", 8, "For determination and persistence"},
      {"A", "Ambition", 7, "For setting and achieving goals"}
    ]
  end

  defp member_options(members) do
    Enum.map(members, &{&1.name, &1.id})
  end

  defp receiver_options(members, current_user) do
    members
    |> Enum.reject(&(&1.id == (current_user && current_user.id)))  # Exclude current user
    |> Enum.map(&{"#{&1.name} (#{&1.house.name})", &1.id})
  end

  defp trait_options(traits) do
    traits
    |> Enum.sort_by(&((&1.house && &1.house.name) || ""))
    |> Enum.map(&{"#{&1.name} - #{&1.description}", &1.id})
  end

  defp trait_emoji(trait_name) do
    case trait_name do
      "Courage" -> "🦁"
      "Initiative" -> "⚡"
      "Boldness" -> "🔥"
      "Teamwork" -> "🤝"
      "Loyalty" -> "💛"
      "Steadfastness" -> "🛡️"
      "Curiosity" -> "🦅"
      "Insight" -> "🔍"
      "Cleverness" -> "💡"
      "Ambition" -> "🐍"
      "Resourcefulness" -> "⚙️"
      "Drive" -> "🎯"
      _ -> "✨"
    end
  end
end