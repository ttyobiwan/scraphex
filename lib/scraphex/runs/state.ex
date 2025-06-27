defmodule Scraphex.Runs.State do
  defstruct [
    :run,
    :base_url,
    :visited,
    :depth,
    :total_processed
  ]
end
