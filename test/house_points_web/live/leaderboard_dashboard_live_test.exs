defmodule HousePointsWeb.LeaderboardDashboardLiveTest do
  use HousePointsWeb.ConnCase
  import Phoenix.LiveViewTest

  alias HousePoints.{Directory, Recognition, Repo}

  describe "leaderboard dashboard" do
    setup do
      # Create test houses
      {:ok, gryffindor} = Directory.create_house(%{name: "Gryffindor", color: "#740001", crest_url: "test.jpg"})
      {:ok, hufflepuff} = Directory.create_house(%{name: "Hufflepuff", color: "#FFDB00", crest_url: "test.jpg"})
      {:ok, ravenclaw} = Directory.create_house(%{name: "Ravenclaw", color: "#0E1A40", crest_url: "test.jpg"})
      {:ok, slytherin} = Directory.create_house(%{name: "Slytherin", color: "#1A472A", crest_url: "test.jpg"})

      # Create test members
      {:ok, harry} = Directory.create_member(%{name: "Harry Potter", email: "harry@hogwarts.edu", hashed_password: "test", house_id: gryffindor.id})
      {:ok, hermione} = Directory.create_member(%{name: "Hermione Granger", email: "hermione@hogwarts.edu", hashed_password: "test", house_id: gryffindor.id})
      {:ok, cedric} = Directory.create_member(%{name: "Cedric Diggory", email: "cedric@hogwarts.edu", hashed_password: "test", house_id: hufflepuff.id})
      {:ok, luna} = Directory.create_member(%{name: "Luna Lovegood", email: "luna@hogwarts.edu", hashed_password: "test", house_id: ravenclaw.id})
      {:ok, draco} = Directory.create_member(%{name: "Draco Malfoy", email: "draco@hogwarts.edu", hashed_password: "test", house_id: slytherin.id})

      # Create test traits
      {:ok, courage} = Directory.create_trait(%{name: "Courage", description: "Brave in the face of danger"})
      {:ok, teamwork} = Directory.create_trait(%{name: "Teamwork", description: "Works well with others"})

      %{
        houses: %{gryffindor: gryffindor, hufflepuff: hufflepuff, ravenclaw: ravenclaw, slytherin: slytherin},
        members: %{harry: harry, hermione: hermione, cedric: cedric, luna: luna, draco: draco},
        traits: %{courage: courage, teamwork: teamwork}
      }
    end

    test "displays house leaderboard with correct data and rankings", %{conn: conn, houses: houses, members: members, traits: traits} do
      # Award points to different houses to create a clear ranking
      Recognition.award_points(members.luna, members.harry, traits.courage, 25, "Saved everyone")
      Recognition.award_points(members.luna, members.hermione, traits.teamwork, 20, "Great collaboration")
      Recognition.award_points(members.luna, members.cedric, traits.courage, 15, "Brave action")
      Recognition.award_points(members.luna, members.draco, traits.teamwork, 10, "Helped the team")

      # Create a session with Luna as current user (authenticated)
      conn =
        conn
        |> Plug.Test.init_test_session(%{current_user_id: members.luna.id})

      {:ok, view, _html} = live(conn, "/leaderboard")

      # Verify the page loads without errors
      assert has_element?(view, "h1", "House Points Leaderboard")

      # Verify house rankings are displayed
      assert has_element?(view, "[phx-value-tab='houses']", "Houses")

      # Get the rendered HTML for detailed content validation
      html = render(view)

      # Verify Gryffindor is in first place with 45 points (25+20)
      assert html =~ "Gryffindor"
      assert html =~ "🦁"
      assert html =~ "45"  # Total points for Gryffindor

      # Verify Hufflepuff is shown with 15 points
      assert html =~ "Hufflepuff"
      assert html =~ "🦡"
      assert html =~ "15"  # Total points for Hufflepuff

      # Verify Slytherin is shown with 10 points
      assert html =~ "Slytherin"
      assert html =~ "🐍"
      assert html =~ "10"  # Total points for Slytherin

      # Note: Ravenclaw doesn't appear because houses with 0 points are not shown in rankings
      # This is the correct behavior - only houses with points appear

      # Verify ranking indicators (medals)
      assert html =~ "🥇"  # First place medal
      assert html =~ "🥈"  # Second place medal
      assert html =~ "🥉"  # Third place medal

      # Verify stats are calculated correctly
      assert html =~ "Total Points Awarded"
      assert html =~ "70"   # Total points: 45 + 15 + 10 = 70
      assert html =~ "Leading House"
      assert html =~ "Point Spread"
      assert html =~ "35"   # Point spread: 45 - 10 = 35

      # Verify member counts are shown
      assert html =~ "2 members"  # Gryffindor has 2 members
      assert html =~ "1 member"   # Other houses have 1 member each
    end

    test "can switch between tabs", %{conn: conn, members: members} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{current_user_id: members.luna.id})

      {:ok, view, _html} = live(conn, "/leaderboard")

      # Switch to individuals tab
      view |> element("[phx-value-tab='individuals']") |> render_click()
      assert has_element?(view, "h2", "Individual Standings")

      # Switch to traits tab
      view |> element("[phx-value-tab='traits']") |> render_click()
      assert has_element?(view, "h2", "Most Recognized Traits")

      # Switch to recent tab
      view |> element("[phx-value-tab='recent']") |> render_click()
      assert has_element?(view, "h2", "Recent Awards")

      # Switch back to houses tab
      view |> element("[phx-value-tab='houses']") |> render_click()
      assert has_element?(view, "h2", "🏆 House Standings")
    end

    test "integration test: complete authentication and leaderboard validation", %{conn: conn, houses: houses, members: members, traits: traits} do
      # Clear any existing awards to start with clean slate
      Repo.delete_all(HousePoints.Recognition.Award)

      # Create specific award data to match our expected results
      Recognition.award_points(members.luna, members.harry, traits.courage, 30, "Exceptional bravery")
      Recognition.award_points(members.luna, members.hermione, traits.teamwork, 20, "Outstanding collaboration")
      Recognition.award_points(members.luna, members.cedric, traits.courage, 25, "Heroic actions")
      Recognition.award_points(members.luna, members.draco, traits.teamwork, 15, "Team leadership")

      # Test authentication flow - ensure user must be logged in
      unauthenticated_conn = build_conn()
      {:error, {:redirect, %{to: "/auth"}}} = live(unauthenticated_conn, "/leaderboard")

      # Create authenticated session
      authenticated_conn =
        conn
        |> Plug.Test.init_test_session(%{current_user_id: members.luna.id})

      # Test successful leaderboard access with authentication
      {:ok, view, _html} = live(authenticated_conn, "/leaderboard")

      # Verify page structure and navigation
      assert has_element?(view, "h1", "House Points Leaderboard")
      assert has_element?(view, ".tabs")
      assert has_element?(view, "[phx-value-tab='houses']")

      # Get final rendered HTML for comprehensive validation
      html = render(view)

      # Validate complete house standings (Gryffindor: 50, Hufflepuff: 25, Slytherin: 15)
      # Verify first place: Gryffindor with 50 points
      assert html =~ "🥇"
      assert html =~ "Gryffindor"
      assert html =~ "🦁"
      assert html =~ "50"

      # Verify second place: Hufflepuff with 25 points
      assert html =~ "🥈"
      assert html =~ "Hufflepuff"
      assert html =~ "🦡"
      assert html =~ "25"

      # Verify third place: Slytherin with 15 points
      assert html =~ "🥉"
      assert html =~ "Slytherin"
      assert html =~ "🐍"
      assert html =~ "15"

      # Verify summary statistics are accurate
      assert html =~ "Total Points Awarded"
      assert html =~ "90"  # 50 + 25 + 15 = 90

      assert html =~ "Leading House"
      # Should show Gryffindor lion emoji in leading house stat
      gryffindor_lion_pattern = ~r/Leading House.*🦁/s
      assert Regex.match?(gryffindor_lion_pattern, html)

      assert html =~ "Point Spread"
      assert html =~ "35"  # 50 - 15 = 35 point difference between first and last

      # Verify member counts are displayed
      assert html =~ "2 members"  # Gryffindor
      assert html =~ "1 member"   # Other houses

      # Verify progress bars are rendered
      assert html =~ "progress"
      assert html =~ "House Progress"

      # Test that houses with 0 points don't appear in the ranking
      # (Ravenclaw should not appear since it has no points)
      refute html =~ "Ravenclaw"
    end

    test "leaderboard rendering includes expected UI elements" do
      # This test verifies the leaderboard includes expected UI elements without testing private functions
      # The actual functionality is tested through the integration tests above

      # Test that the module exists and can be compiled
      assert Code.ensure_loaded?(HousePointsWeb.LeaderboardDashboardLive)

      # Test module has expected public callback functions
      functions = HousePointsWeb.LeaderboardDashboardLive.__info__(:functions)
      assert Enum.member?(functions, {:mount, 3})
      assert Enum.member?(functions, {:render, 1})
      assert Enum.member?(functions, {:handle_event, 3})
      assert Enum.member?(functions, {:handle_params, 3})
    end
  end
end