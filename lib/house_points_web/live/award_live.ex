defmodule HousePointsWeb.AwardLive do
  use HousePointsWeb, :live_view

  alias HousePoints.{Recognition, Directory}
  alias HousePoints.Recognition.Award

  @impl true
  def mount(_params, _session, socket) do
    changeset = Award.changeset(%Award{}, %{})

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:form, to_form(changeset))
      |> assign(:members, Directory.list_members())
      |> assign(:traits, Directory.list_traits())

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"award" => award_params}, socket) do
    changeset =
      %Award{}
      |> Award.changeset(award_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:form, to_form(changeset))

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"award" => award_params}, socket) do
    case create_award(award_params) do
      {:ok, _award} ->
        socket =
          socket
          |> put_flash(:info, "Award created successfully!")
          |> push_navigate(to: ~p"/leaderboard")

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:changeset, changeset)
          |> assign(:form, to_form(changeset))

        {:noreply, socket}

      {:error, :self_award_not_allowed} ->
        socket = put_flash(socket, :error, "You cannot award points to yourself!")
        {:noreply, socket}

      {:error, :daily_limit_exceeded} ->
        socket = put_flash(socket, :error, "Daily point limit exceeded!")
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 max-w-2xl">
      <h1 class="text-3xl font-bold mb-8 text-center">Award Points</h1>

      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <.form for={@form} phx-change="validate" phx-submit="save">
            <div class="form-control mb-4">
              <label class="label">
                <span class="label-text">Giver (You)</span>
              </label>
              <!-- TODO: Get current user from session -->
              <.input field={@form[:giver_id]} type="select" options={member_options(@members)} prompt="Select giver..." />
            </div>

            <div class="form-control mb-4">
              <label class="label">
                <span class="label-text">Receiver</span>
              </label>
              <.input field={@form[:receiver_id]} type="select" options={member_options(@members)} prompt="Select receiver..." />
            </div>

            <div class="form-control mb-4">
              <label class="label">
                <span class="label-text">Trait</span>
              </label>
              <.input field={@form[:trait_id]} type="select" options={trait_options(@traits)} prompt="Select trait..." />
            </div>

            <div class="form-control mb-4">
              <label class="label">
                <span class="label-text">Points</span>
              </label>
              <.input field={@form[:points]} type="number" min="1" max="50" placeholder="Enter points..." />
            </div>

            <div class="form-control mb-6">
              <label class="label">
                <span class="label-text">Reason</span>
              </label>
              <.input field={@form[:reason]} type="textarea" rows="3" placeholder="Why are you awarding these points?" />
            </div>

            <div class="form-control">
              <.button type="submit" disabled={!@changeset.valid?} class="btn btn-primary">
                Award Points
              </.button>
            </div>
          </.form>
        </div>
      </div>

      <!-- Quick Award Buttons -->
      <div class="mt-8">
        <h3 class="text-xl font-semibold mb-4">Quick Awards</h3>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <!-- TODO: Implement emoji quick-picks -->
          <button class="btn btn-outline">🏆 Excellence (10pts)</button>
          <button class="btn btn-outline">🤝 Teamwork (5pts)</button>
          <button class="btn btn-outline">💡 Innovation (8pts)</button>
          <button class="btn btn-outline">🚀 Initiative (7pts)</button>
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

  defp member_options(members) do
    Enum.map(members, &{&1.name, &1.id})
  end

  defp trait_options(traits) do
    Enum.map(traits, &{"#{&1.name} - #{&1.description}", &1.id})
  end
end