defmodule Scraphex.Http.Client do
  @callback get(url :: String.t(), opts :: keyword()) ::
              {:ok, %{status: integer(), body: binary(), final_url: String.t()}}
              | {:error, term()}
end
