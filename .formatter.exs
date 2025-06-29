# Used by "mix format"
[
  import_deps: [:ecto, :ecto_sql],
  subdirectories: ["priv/*/migrations"],
  inputs: ["{mix,.formatter,.iex}.exs", "{config,lib,test}/**/*.{ex,exs,eex}", "priv/*/seeds.exs"]
]
