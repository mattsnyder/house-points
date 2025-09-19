defmodule HousePoints.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HousePointsWeb.Telemetry,
      HousePoints.Repo,
      {DNSCluster, query: Application.get_env(:house_points, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HousePoints.PubSub},
      # Start a worker by calling: HousePoints.Worker.start_link(arg)
      # {HousePoints.Worker, arg},
      # Start to serve requests, typically the last entry
      HousePointsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HousePoints.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HousePointsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
