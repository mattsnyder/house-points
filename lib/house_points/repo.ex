defmodule HousePoints.Repo do
  use Ecto.Repo,
    otp_app: :house_points,
    adapter: Ecto.Adapters.Postgres
end
