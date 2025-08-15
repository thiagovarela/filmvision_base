defmodule Filmvision.Repo do
  use Ecto.Repo,
    otp_app: :filmvision,
    adapter: Ecto.Adapters.Postgres
end
