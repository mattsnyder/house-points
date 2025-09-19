defmodule HousePointsWeb.AwardLive do
  use HousePointsWeb, :live_view
  import Ecto.Query

  alias HousePoints.{Recognition, Directory}
  alias HousePoints.Recognition.Award

  @impl true
  def mount(_params, _session, socket) do
    changeset = Award.changeset(%Award{}, %{})

    # For demo purposes, we'll use the first member as the current user
    # In a real app, this would come from session/auth
    current_user = Directory.list_members() |> List.first()

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:form, to_form(changeset))
      |> assign(:members, Directory.list_members())
      |> assign(:traits, Directory.list_traits())
      |> assign(:current_user, current_user)
      |> assign(:daily_points_given, get_daily_points_given(current_user))
      |> assign(:daily_limit, get_daily_limit())

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
      |> Award.changeset(award_params)
      |> Map.put(:action, :validate)

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

      changeset = Award.changeset(%Award{}, award_params)

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
    <div class="container mx-auto px-4 py-8 max-w-4xl">
      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold mb-2">🏆 Award Points</h1>
        <%= if @current_user do %>
          <p class="text-lg">Welcome, <strong><%= @current_user.name %></strong>!</p>
          <div class="badge badge-info">
            <%= @remaining_points %> / <%= @daily_limit %> points remaining today
          </div>
        <% end %>
      </div>

      <div class="grid lg:grid-cols-2 gap-8">
        <!-- Award Form -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-xl mb-4">🎯 Custom Award</h2>

            <.form for={@form} phx-change="validate" phx-submit="save">
              <%= if @current_user do %>
                <input type="hidden" name="award[giver_id]" value={@current_user.id} />
                <div class="form-control mb-4">
                  <label class="label">
                    <span class="label-text font-semibold">From: <%= @current_user.name %></span>
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
                  <span class="label-text font-semibold">To: <span class="text-error">*</span></span>
                </label>
                <.input field={@form[:receiver_id]} type="select" options={receiver_options(@members, @current_user)} prompt="Select who you're recognizing..." />
              </div>

              <div class="form-control mb-4">
                <label class="label">
                  <span class="label-text font-semibold">For demonstrating: <span class="text-error">*</span></span>
                </label>
                <.input field={@form[:trait_id]} type="select" options={trait_options(@traits)} prompt="Select a trait..." />
              </div>

              <div class="form-control mb-4">
                <label class="label">
                  <span class="label-text font-semibold">Points (1-50) <span class="text-error">*</span></span>
                  <%= if assigns[:show_limit_warning] && @show_limit_warning do %>
                    <span class="label-text-alt text-warning">⚠️ Exceeds daily limit!</span>
                  <% end %>
                </label>
                <.input field={@form[:points]} type="number" min="1" max="50" placeholder="How many points?" />
              </div>

              <div class="form-control mb-6">
                <label class="label">
                  <span class="label-text font-semibold">Why? <span class="text-error">*</span></span>
                  <span class="label-text-alt">Be specific about what they did!</span>
                </label>
                <.input field={@form[:reason]} type="textarea" rows="3" placeholder="Describe what they did that exemplified this trait..." />
              </div>

              <div class="form-control">
                <.button type="submit" disabled={!@changeset.valid? || (assigns[:show_limit_warning] && @show_limit_warning)} class="btn btn-primary btn-lg w-full">
                  🎉 Award Points
                </.button>
              </div>
            </.form>
          </div>
        </div>

        <!-- Quick Awards -->
        <div class="space-y-6">
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-xl mb-4">⚡ Quick Awards</h2>
              <p class="text-sm text-base-content/70 mb-4">Click to pre-fill the form with common awards:</p>

              <div class="grid grid-cols-1 gap-3">
                <%= for {emoji, trait, points, description} <- quick_award_options() do %>
                  <button
                    phx-click="quick_award"
                    phx-value-trait={trait}
                    phx-value-points={points}
                    class={"btn btn-outline text-left justify-start #{if assigns[:quick_award_selected] == trait, do: "btn-active"}"}
                  >
                    <span class="text-2xl mr-3"><%= emoji %></span>
                    <div class="text-left">
                      <div class="font-semibold"><%= trait %> (<%= points %>pts)</div>
                      <div class="text-xs opacity-70"><%= description %></div>
                    </div>
                  </button>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Daily Stats -->
          <%= if @current_user do %>
            <div class="card bg-gradient-to-r from-primary to-secondary text-primary-content shadow-xl">
              <div class="card-body">
                <h3 class="card-title text-lg">📊 Your Daily Progress</h3>
                <div class="stats stats-vertical bg-transparent text-primary-content">
                  <div class="stat">
                    <div class="stat-title text-primary-content/70">Points Given Today</div>
                    <div class="stat-value text-2xl"><%= @daily_points_given %></div>
                  </div>
                  <div class="stat">
                    <div class="stat-title text-primary-content/70">Remaining</div>
                    <div class="stat-value text-2xl"><%= @remaining_points %></div>
                  </div>
                </div>
                <progress class="progress progress-primary bg-primary-content/20" value={@daily_points_given} max={@daily_limit}></progress>
              </div>
            </div>
          <% end %>
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
      {"🏆", "Courage", 10, "For bravery in challenging situations"},
      {"🤝", "Teamwork", 8, "For excellent collaboration"},
      {"💡", "Cleverness", 7, "For creative problem solving"},
      {"🚀", "Initiative", 9, "For taking action and leading"},
      {"💎", "Loyalty", 6, "For commitment and reliability"},
      {"🔍", "Curiosity", 5, "For asking great questions"},
      {"⚡", "Drive", 8, "For determination and persistence"},
      {"🎯", "Ambition", 7, "For setting and achieving goals"}
    ]
  end

  defp member_options(members) do
    Enum.map(members, &{&1.name, &1.id})
  end

  defp receiver_options(members, current_user) do
    members
    |> Enum.reject(&(&1.id == current_user&.id))  # Exclude current user
    |> Enum.map(&{"#{&1.name} (#{&1.house.name})", &1.id})
  end

  defp trait_options(traits) do
    traits
    |> Enum.sort_by(&(&1.house&.name || ""))
    |> Enum.map(&{"#{trait_emoji(&1.name)} #{&1.name} - #{&1.description}", &1.id})
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