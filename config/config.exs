import Config

config :scraphex,
  ecto_repos: [Scraphex.Repo]

config :logger, :console, format: "$time $metadata[$level] $message\n"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
