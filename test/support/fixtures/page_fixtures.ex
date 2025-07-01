defmodule Scraphex.PageFixtures do
  alias Scraphex.Pages
  alias Scraphex.RunFixtures

  def valid_run_attrs(attrs \\ %{}) do
    run_id =
      Map.get_lazy(attrs, :run_id, fn ->
        RunFixtures.run_fixture().id
      end)

    Map.merge(%{url: "/", title: "Scraphex", run_id: run_id}, attrs)
  end

  def page_fixture(attrs \\ %{}) do
    attrs
    |> valid_run_attrs()
    |> Pages.create_page!()
  end
end
