defmodule Scraphex.Pages do
  alias Scraphex.Pages.PageLink
  alias Scraphex.Pages.Page
  alias Scraphex.Repo
  import Ecto.Query

  @doc """
  Creates a new page.
  """
  def create_page!(attrs \\ %{}) do
    %Page{}
    |> Page.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Create links between page and linked pages.
  """
  def create_links(page, linked_pages) do
    linked_pages
    |> Enum.map(fn lpage -> %{page_id: page.id, linked_page_id: lpage.id} end)
    |> tap(fn changesets -> Repo.insert_all(PageLink, changesets) end)
  end

  @doc """
  Get pages by the list of urls and run id.
  """
  def get_pages_by_urls_and_run(urls, run_id) do
    Repo.all(from(p in Page, where: p.url in ^urls and p.run_id == ^run_id, select: %{id: p.id}))
  end
end
