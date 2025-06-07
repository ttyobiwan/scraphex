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
  Creates a new page link.
  """
  def create_link!(attrs \\ %{}) do
    %PageLink{}
    |> PageLink.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Gets page by url and run id.
  """
  def get_page_by_url_and_run(url, run_id) do
    Repo.one(
      from p in Page,
        where: p.url == ^url and p.run_id == ^run_id
    )
  end
end
