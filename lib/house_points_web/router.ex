defmodule HousePointsWeb.Router do
  use HousePointsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HousePointsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HousePointsWeb do
    pipe_through :browser

    # Authentication routes
    live "/auth", AuthLive, :index
    get "/auth/callback", AuthController, :callback
    live "/auth/house-selection", HouseSelectionLive, :index

    # Redirect root to leaderboard (will redirect to auth if not logged in)
    live "/", LeaderboardDashboardLive, :index

    # Main application routes
    live "/leaderboard", LeaderboardDashboardLive, :index
    live "/award", AwardLive, :index
    live "/recap", RecapLive, :index

    # Admin routes
    live "/admin", AdminLive, :index
    live "/admin/houses", AdminLive, :houses
    live "/admin/traits", AdminLive, :traits
    live "/admin/members", AdminLive, :members
    live "/admin/rules", AdminLive, :rules
    live "/admin/audit", AdminLive, :audit
  end

  # Other scopes may use custom stacks.
  # scope "/api", HousePointsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:house_points, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HousePointsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
