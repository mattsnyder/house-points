defmodule HousePointsWeb.AuthLive do
  use HousePointsWeb, :live_view

  alias HousePoints.{Auth, Directory.Member, Directory}

  on_mount {HousePointsWeb.AuthPlug, :assign_current_user}

  @impl true
  def mount(params, session, socket) do
    current_user = get_current_user(session)

    # Redirect if already authenticated
    if current_user do
      if Auth.needs_house_selection?(current_user) do
        {:ok, push_navigate(socket, to: ~p"/auth/house-selection")}
      else
        {:ok, push_navigate(socket, to: ~p"/leaderboard")}
      end
    else
      # Check if we should show signup or login mode
      mode = Map.get(params, "mode", "login")

      houses = Directory.list_houses()

      socket =
        socket
        |> assign(:current_user, current_user)
        |> assign(:page_title, "Welcome to House Points")
        |> assign(:mode, mode)
        |> assign(:houses, houses)
        |> assign(:login_form, to_form(Member.login_changeset(%Member{}, %{}), as: :member))
        |> assign(:signup_form, to_form(Member.registration_changeset(%Member{}, %{house_id: nil}), as: :member))

      {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    mode = Map.get(params, "mode", "login")
    socket = assign(socket, :mode, mode)
    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_mode", %{"mode" => mode}, socket) do
    {:noreply, push_patch(socket, to: ~p"/auth?mode=#{mode}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900">
      <div class="container mx-auto px-4 py-8">
        <!-- Flash Messages -->
        <%= if @flash["error"] do %>
          <div class="alert alert-error mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span><%= @flash["error"] %></span>
          </div>
        <% end %>
        <%= if @flash["info"] do %>
          <div class="alert alert-info mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <span><%= @flash["info"] %></span>
          </div>
        <% end %>

        <div class="flex items-center justify-center min-h-screen">
          <div class="max-w-md w-full">
            <!-- Logo and Title -->
            <div class="text-center mb-8">
              <div class="text-6xl mb-4">🏰</div>
              <h1 class="text-4xl font-bold text-white mb-2">House Points</h1>
              <p class="text-xl text-gray-200">Where magic meets recognition</p>
            </div>

            <!-- Auth Card -->
            <div class="card bg-base-100 shadow-2xl">
              <div class="card-body">
                <%= if @mode == "login" do %>
                  <h2 class="card-title text-2xl justify-center mb-6">Welcome Back</h2>

                  <.form for={@login_form} action={~p"/auth/login"} method="post" class="space-y-4">
                    <div class="form-control">
                      <label class="label">
                        <span class="label-text font-semibold">Email</span>
                      </label>
                      <.input field={@login_form[:email]} type="email" placeholder="your@email.com" required />
                    </div>

                    <div class="form-control">
                      <label class="label">
                        <span class="label-text font-semibold">Password</span>
                      </label>
                      <.input field={@login_form[:password]} type="password" placeholder="Enter your password" required />
                    </div>

                    <div class="form-control mt-6">
                      <.button type="submit" class="btn btn-primary btn-lg w-full">
                        🚀 Sign In
                      </.button>
                    </div>
                  </.form>

                  <div class="divider">New to House Points?</div>

                  <button
                    phx-click="switch_mode"
                    phx-value-mode="signup"
                    class="btn btn-outline w-full"
                  >
                    Create Account
                  </button>
                <% else %>
                  <h2 class="card-title text-2xl justify-center mb-6">Join House Points</h2>

                  <.form for={@signup_form} action={~p"/auth/register"} method="post" class="space-y-4">
                    <div class="form-control">
                      <label class="label">
                        <span class="label-text font-semibold">Name <span class="text-error">*</span></span>
                      </label>
                      <.input field={@signup_form[:name]} type="text" placeholder="Your display name" required />
                    </div>

                    <div class="form-control">
                      <label class="label">
                        <span class="label-text font-semibold">Email <span class="text-error">*</span></span>
                      </label>
                      <.input field={@signup_form[:email]} type="email" placeholder="your@email.com" required />
                    </div>

                    <div class="form-control">
                      <label class="label">
                        <span class="label-text font-semibold">Password <span class="text-error">*</span></span>
                        <span class="label-text-alt">At least 8 characters</span>
                      </label>
                      <.input field={@signup_form[:password]} type="password" placeholder="Create a password" required />
                    </div>

                    <div class="form-control">
                      <label class="label">
                        <span class="label-text font-semibold">Confirm Password <span class="text-error">*</span></span>
                      </label>
                      <.input field={@signup_form[:password_confirmation]} type="password" placeholder="Confirm your password" required />
                    </div>

                    <div class="form-control">
                      <label class="label">
                        <span class="label-text font-semibold">Select Your House <span class="text-error">*</span></span>
                      </label>
                      <.input field={@signup_form[:house_id]} type="select" prompt="Choose your house..." options={Enum.map(@houses, fn house ->
                        {case house.name do
                          "Gryffindor" -> "🦁 Gryffindor"
                          "Hufflepuff" -> "🦡 Hufflepuff"
                          "Ravenclaw" -> "🦅 Ravenclaw"
                          "Slytherin" -> "🐍 Slytherin"
                          _ -> "🏠 #{house.name}"
                        end, house.id}
                      end)} required />
                    </div>

                    <div class="form-control mt-6">
                      <.button type="submit" class="btn btn-primary btn-lg w-full">
                        🎉 Create Account
                      </.button>
                    </div>
                  </.form>

                  <div class="divider">Already have an account?</div>

                  <button
                    phx-click="switch_mode"
                    phx-value-mode="login"
                    class="btn btn-outline w-full"
                  >
                    Sign In
                  </button>
                <% end %>

                <div class="divider">What you'll get</div>

                <!-- Features Preview -->
                <div class="space-y-3">
                  <div class="flex items-center space-x-3 text-sm">
                    <span class="text-2xl">🏆</span>
                    <span>Award points for great work</span>
                  </div>
                  <div class="flex items-center space-x-3 text-sm">
                    <span class="text-2xl">📊</span>
                    <span>Track house leaderboards</span>
                  </div>
                  <div class="flex items-center space-x-3 text-sm">
                    <span class="text-2xl">🎯</span>
                    <span>Recognize team traits</span>
                  </div>
                  <div class="flex items-center space-x-3 text-sm">
                    <span class="text-2xl">📈</span>
                    <span>View weekly recaps</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- House Previews -->
            <div class="grid grid-cols-2 gap-4 mt-8">
              <div class="card bg-red-900 text-white shadow-xl">
                <div class="card-body text-center py-4">
                  <div class="text-2xl">🦁</div>
                  <div class="font-semibold">Gryffindor</div>
                </div>
              </div>
              <div class="card bg-yellow-600 text-white shadow-xl">
                <div class="card-body text-center py-4">
                  <div class="text-2xl">🦡</div>
                  <div class="font-semibold">Hufflepuff</div>
                </div>
              </div>
              <div class="card bg-blue-900 text-white shadow-xl">
                <div class="card-body text-center py-4">
                  <div class="text-2xl">🦅</div>
                  <div class="font-semibold">Ravenclaw</div>
                </div>
              </div>
              <div class="card bg-green-800 text-white shadow-xl">
                <div class="card-body text-center py-4">
                  <div class="text-2xl">🐍</div>
                  <div class="font-semibold">Slytherin</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp get_current_user(session) do
    case session["current_user_id"] do
      nil -> nil
      user_id -> HousePoints.Repo.get(HousePoints.Directory.Member, user_id) |> HousePoints.Repo.preload(:house)
    end
  end
end