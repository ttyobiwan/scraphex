defmodule Scraphex.Runs do
  alias Scraphex.Pages
  alias Scraphex.Scrapper
  alias Scraphex.Runs.Run
  alias Scraphex.Repo
  require Logger

  # todo: actual scheduling
  # todo: better link building
  # todo: different architecture

  @doc """
  Creates a new run object and schedules the start of the scraping process.
  """
  def start_run(url) do
    # todo: sync
    run = create_run!(%{url: url})

    # todo: async
    mark_run_as_started!(run)
    process_page(run.id, url)
    mark_run_as_completed!(run)
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
  Marks run as started.
  """
  def mark_run_as_started!(run = %Run{}) do
    run
    |> Run.status_changeset(%{status: :started, started_at: DateTime.utc_now()})
    |> Repo.update!()
  end

  @doc """
  Marks run as completed.
  """
  def mark_run_as_completed!(run = %Run{}) do
    run
    |> Run.status_changeset(%{status: :completed, completed_at: DateTime.utc_now()})
    |> Repo.update!()
  end

  defp process_page(run_id, page_url, from_page_id \\ nil) do
    Logger.info(
      "Processing page: #{inspect(%{run_id: run_id, page_url: page_url, from_page_id: from_page_id})}"
    )

    # Check if page was processed in this run
    # If no, we move forward with processing the page
    # Otherwise, just create a link from the previous page, and stop here
    case Pages.get_page_by_url_and_run(get_clean_link(page_url), run_id) do
      nil ->
        scrap_page(run_id, page_url, from_page_id)

      existing_page ->
        Logger.info(
          "Page already processed, saving link: #{inspect(%{run_id: run_id, page_id: from_page_id, linked_page_id: existing_page.id})}"
        )

        Pages.create_link!(%{page_id: from_page_id, linked_page_id: existing_page.id})
    end
  end

  defp scrap_page(run_id, page_url, from_page_id) do
    Logger.info(
      "Starting to scrap the page: #{inspect(%{run_id: run_id, page_url: page_url, from_page_id: from_page_id})}"
    )

    case Scrapper.scrap(page_url) do
      {:ok, doc} ->
        title = Scrapper.get_title(doc)
        links = Scrapper.get_relative_links(doc)
        page = Pages.create_page!(%{url: get_clean_link(page_url), title: title, run_id: run_id})

        Logger.info(
          "Scrap done: #{inspect(%{run_id: run_id, page_id: page.id, from_page_id: from_page_id, links: links})}"
        )

        if from_page_id != nil do
          Logger.info(
            "Saving link: #{inspect(%{run_id: run_id, page_id: page.id, from_page_id: from_page_id})}"
          )

          Pages.create_link!(%{page_id: from_page_id, linked_page_id: page.id})
        end

        Enum.each(links, fn link ->
          process_page(
            run_id,
            get_base_url(page_url) <> "/" <> String.trim(link, "/") <> "/",
            page.id
          )
        end)

      {:error, reason} ->
        Logger.error("Error when scraping: #{reason}")
    end
  end

  defp get_clean_link(href) do
    href
    |> URI.parse()
    |> Map.put(:query, nil)
    |> Map.put(:fragment, nil)
    |> URI.to_string()
  end

  defp get_base_url(url) do
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}"
  end
end
