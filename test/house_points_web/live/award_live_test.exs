defmodule HousePointsWeb.AwardLiveTest do
  use HousePointsWeb.ConnCase
  import Phoenix.LiveViewTest

  alias HousePoints.{Directory, Recognition, Repo}

  describe "award live" do
    setup do
      # Create test houses
      {:ok, gryffindor} = Directory.create_house(%{name: "Gryffindor", color: "#740001", crest_url: "test.jpg"})
      {:ok, hufflepuff} = Directory.create_house(%{name: "Hufflepuff", color: "#FFDB00", crest_url: "test.jpg"})

      # Create test members
      {:ok, harry} = Directory.create_member(%{name: "Harry Potter", email: "harry@hogwarts.edu", hashed_password: "test", house_id: gryffindor.id})
      {:ok, hermione} = Directory.create_member(%{name: "Hermione Granger", email: "hermione@hogwarts.edu", hashed_password: "test", house_id: gryffindor.id})
      {:ok, cedric} = Directory.create_member(%{name: "Cedric Diggory", email: "cedric@hogwarts.edu", hashed_password: "test", house_id: hufflepuff.id})

      # Create test traits
      {:ok, courage} = Directory.create_trait(%{name: "Courage", description: "Brave in the face of danger"})
      {:ok, teamwork} = Directory.create_trait(%{name: "Teamwork", description: "Works well with others"})

      %{
        houses: %{gryffindor: gryffindor, hufflepuff: hufflepuff},
        members: %{harry: harry, hermione: hermione, cedric: cedric},
        traits: %{courage: courage, teamwork: teamwork}
      }
    end

    test "requires authentication to access award page", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/auth"}}} = live(conn, "/award")
    end

    test "authenticated user can access award page", %{conn: conn, members: members} do
      conn = conn |> Plug.Test.init_test_session(%{current_user_id: members.harry.id})

      {:ok, view, _html} = live(conn, "/award")

      assert has_element?(view, "h1", "Award Points")
      assert has_element?(view, "form")
      assert has_element?(view, "button[type='submit']")
    end

    test "form starts with disabled submit button", %{conn: conn, members: members} do
      conn = conn |> Plug.Test.init_test_session(%{current_user_id: members.harry.id})

      {:ok, view, _html} = live(conn, "/award")

      # Submit button should be disabled initially
      assert has_element?(view, "button[disabled][type='submit']")
    end

    test "form enables submit button when all required fields are filled", %{conn: conn, members: members, traits: traits} do
      conn = conn |> Plug.Test.init_test_session(%{current_user_id: members.harry.id})

      {:ok, view, _html} = live(conn, "/award")

      # Fill out all required fields
      form_data = %{
        "receiver_id" => to_string(members.hermione.id),
        "trait_id" => to_string(traits.courage.id),
        "points" => "10",
        "reason" => "Showed great courage in the face of danger"
      }

      # Submit the form data to trigger validation
      view
      |> form("form", award: form_data)
      |> render_change()

      # Submit button should now be enabled
      refute has_element?(view, "button[disabled][type='submit']")
      assert has_element?(view, "button[type='submit']:not([disabled])")
    end

    test "form validation shows errors for invalid data", %{conn: conn, members: members, traits: traits} do
      conn = conn |> Plug.Test.init_test_session(%{current_user_id: members.harry.id})

      {:ok, view, _html} = live(conn, "/award")

      # Submit invalid data (reason too short, points too high)
      form_data = %{
        "receiver_id" => to_string(members.hermione.id),
        "trait_id" => to_string(traits.courage.id),
        "points" => "100", # Too high (max is 50)
        "reason" => "Bad" # Too short (min is 5 chars)
      }

      view
      |> form("form", award: form_data)
      |> render_change()

      # Submit button should remain disabled due to validation errors
      assert has_element?(view, "button[disabled][type='submit']")
    end

    test "can successfully submit valid award", %{conn: conn, members: members, traits: traits} do
      conn = conn |> Plug.Test.init_test_session(%{current_user_id: members.harry.id})

      {:ok, view, _html} = live(conn, "/award")

      # Fill out valid form data
      form_data = %{
        "receiver_id" => to_string(members.hermione.id),
        "trait_id" => to_string(traits.courage.id),
        "points" => "10",
        "reason" => "Showed great courage in the face of danger"
      }

      # Submit the form
      view
      |> form("form", award: form_data)
      |> render_submit()

      # Should redirect to leaderboard
      assert_redirected(view, "/leaderboard")

      # Verify award was created in database
      award = Repo.one(Recognition.Award)
      assert award.giver_id == members.harry.id
      assert award.receiver_id == members.hermione.id
      assert award.trait_id == traits.courage.id
      assert award.points == 10
      assert award.reason == "Showed great courage in the face of danger"
    end

    test "prevents self-awards", %{conn: conn, members: members, traits: traits} do
      conn = conn |> Plug.Test.init_test_session(%{current_user_id: members.harry.id})

      {:ok, view, _html} = live(conn, "/award")

      # Try to award points to self
      form_data = %{
        "receiver_id" => to_string(members.harry.id), # Same as giver
        "trait_id" => to_string(traits.courage.id),
        "points" => "10",
        "reason" => "Trying to award myself points"
      }

      view
      |> form("form", award: form_data)
      |> render_submit()

      # Should show error message and not redirect
      assert render(view) =~ "You cannot award points to yourself"

      # No award should be created
      assert Repo.all(Recognition.Award) == []
    end

    test "quick awards pre-fill form correctly", %{conn: conn, members: members} do
      conn = conn |> Plug.Test.init_test_session(%{current_user_id: members.harry.id})

      {:ok, view, _html} = live(conn, "/award")

      # Click on a quick award button
      view
      |> element("button[phx-value-trait='Courage']")
      |> render_click()

      # Form should be pre-filled with quick award data
      html = render(view)
      assert html =~ "Showed courage and bravery in a challenging situation"
    end

    test "displays daily limit correctly", %{conn: conn, members: members} do
      conn = conn |> Plug.Test.init_test_session(%{current_user_id: members.harry.id})

      {:ok, view, _html} = live(conn, "/award")

      # Should show daily limit (either 30 default or 100 from rules)
      html = render(view)
      assert html =~ ~r/\d+ \/ \d+ points remaining today/
    end

    test "daily limit warning appears when trying to exceed limit", %{conn: conn, members: members, traits: traits} do
      conn = conn |> Plug.Test.init_test_session(%{current_user_id: members.harry.id})

      {:ok, view, _html} = live(conn, "/award")

      # Enter points that would exceed daily limit
      form_data = %{
        "receiver_id" => to_string(members.hermione.id),
        "trait_id" => to_string(traits.courage.id),
        "points" => "200", # Way over any reasonable limit
        "reason" => "This should trigger a warning"
      }

      view
      |> form("form", award: form_data)
      |> render_change()

      # Should show limit warning and disable submit button
      html = render(view)
      assert html =~ "Exceeds daily limit"
      assert has_element?(view, "button[disabled][type='submit']")
    end

    test "receiver dropdown excludes current user", %{conn: conn, members: members} do
      conn = conn |> Plug.Test.init_test_session(%{current_user_id: members.harry.id})

      {:ok, view, _html} = live(conn, "/award")

      html = render(view)

      # Current user (Harry) should not appear in receiver dropdown
      refute html =~ "Harry Potter (Gryffindor)"

      # Other users should appear
      assert html =~ "Hermione Granger (Gryffindor)"
      assert html =~ "Cedric Diggory (Hufflepuff)"
    end
  end
end