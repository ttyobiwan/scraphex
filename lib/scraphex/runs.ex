defmodule Scraphex.Runs do
  alias Scraphex.Pages
  alias Scraphex.Scrapper
  alias Scraphex.Runs.Run
  alias Scraphex.Repo
  require Logger

  @doc """
  Creates a new run object and schedules the start of the whole process.
  """
  def start_run(url) do
    # todo: sync
    run = create_run!(%{url: url})

    # todo: async
    mark_run_as!(run, :started)
    process_page(run.id, url)
  end

  @doc """
  Creates a new run object.
  """
  def create_run!(attrs \\ %{}) do
    %Run{}
    |> Run.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Marks run with a status.
  """
  def mark_run_as!(run = %Run{}, status) do
    run
    |> Run.status_changeset(status)
    |> Repo.update!()
  end

  defp process_page(run_id, page_url, from_page_id \\ nil) do
    Logger.info(
      "Processing page: #{inspect(%{run_id: run_id, page_url: page_url, from_page_id: from_page_id})}"
    )

    # Check if page was processed in this run
    # If no, we move forward with processing the page
    # Otherwise, just create a link from the previous page, and stop here
    case Pages.get_page_by_url_and_run(page_url, run_id) do
      nil ->
        scrape_page(run_id, page_url, from_page_id)

      existing_page ->
        Logger.info(
          "Page already processed, saving link: #{inspect(%{run_id: run_id, page_id: from_page_id, linked_page_id: existing_page.id})}"
        )

        Pages.create_link!(%{page_id: from_page_id, linked_page_id: existing_page.id})
    end
  end

  defp scrape_page(run_id, page_url, from_page_id) do
    Logger.info(
      "Starting to scrap the page: #{inspect(%{run_id: run_id, page_url: page_url, from_page_id: from_page_id})}"
    )

    html = Scrapper.scrap(page_url)
    title = Scrapper.get_title(html)
    links = Scrapper.get_links(html)
    page = Pages.create_page!(%{url: page_url, title: title, run_id: run_id})

    if from_page_id != nil do
      Logger.info(
        "Scrap done, saving link: #{inspect(%{run_id: run_id, page_id: page.id, from_page_id: from_page_id})}"
      )

      Pages.create_link!(%{page_id: from_page_id, linked_page_id: page.id})
    end

    Logger.info(
      "Scrap done, reading retrieved links: #{inspect(%{run_id: run_id, page_id: page.id, from_page_id: from_page_id, links: links})}"
    )

    Enum.each(links, fn url -> process_page(run_id, url, page.id) end)
  end
end
