defmodule Scraphex.Http.Client do
  @callback get(url :: String.t(), opts :: keyword()) :: {:ok, map()} | {:error, term()}
end
