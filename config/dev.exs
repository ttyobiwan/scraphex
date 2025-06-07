import Config

config :scraphex, Scraphex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "scraphex_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
