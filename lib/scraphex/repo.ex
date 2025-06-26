defmodule Scraphex.Repo do
  use Ecto.Repo,
    otp_app: :scraphex,
    adapter: Ecto.Adapters.SQLite3
end
