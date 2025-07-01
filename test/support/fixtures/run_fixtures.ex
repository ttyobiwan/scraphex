defmodule Scraphex.RunFixtures do
  alias Scraphex.Runs

  def valid_run_attrs(attrs \\ %{}) do
    Map.merge(%{url: "http://www.scraphex.com/"}, attrs)
  end

  def run_fixture(attrs \\ %{}) do
    attrs
    |> valid_run_attrs()
    |> Runs.create_run()
    |> then(fn {:ok, run} -> run end)
  end
end
