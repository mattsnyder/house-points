import Config

# Configure your database
config :house_points, HousePoints.Repo,
  ssl: true,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "2"),
  ssl_opts: [verify: :verify_none]

# Configure the endpoint
secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
  raise """
  environment variable SECRET_KEY_BASE is missing.
  You can generate one by calling: mix phx.gen.secret
  """

app_name =
  System.get_env("GIGALIXIR_APP_NAME") ||
  System.get_env("APP_NAME") ||
  "localhost"

config :house_points, HousePointsWeb.Endpoint,
  server: true,
  http: [port: {:system, "PORT"}],
  url: [scheme: "https", host: app_name <> ".gigalixirapp.com", port: 443],
  secret_key_base: secret_key_base

# Configure logger level
config :logger, level: :info

# Configure DNS cluster for distributed Elixir
config :house_points, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")