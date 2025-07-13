import Config

# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :scraphex, Scraphex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "scraphex_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Print only criticals during test
config :logger, level: :critical

config :scraphex, :http_client, Scraphex.HttpClientMock
