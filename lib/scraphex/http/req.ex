defmodule Scraphex.Http.Req do
  @behaviour Scraphex.Http.Client

  defdelegate get(url, opts), to: Req
end
