defmodule Scraphex.Runs.Worker do
  alias Scraphex.Pages.Page
  alias Scraphex.Pages
  alias Scraphex.Scrapper
  alias Scraphex.Runs
  alias Scraphex.Runs.Run
  require Logger

  use GenServer

  # --- Client ---

  @doc """
  Schedules start of a run.
  """
  def start_run(run = %Run{}) do
    GenServer.cast(__MODULE__, {:start, run})
  end

  # --- Server ---

  def start_link(_) do
    Logger.info("Starting scrapper worker")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_cast({:start, run = %Run{}}, state) do
    Logger.info("Starting run: run_id=#{run.id}")

    run
    |> Runs.mark_run_as_started!()
    |> tap(fn run -> process_page(run, run.url) end)
    |> Runs.mark_run_as_completed!()

    {:noreply, state}
  end

  # --- Internal ---

  defp process_page(run = %Run{}, current_page_url, previous_page_id \\ nil) do
    Logger.info("Processing page: run_id=#{run.id} page_url=#{current_page_url}")

    current_page_url
    |> get_clean_link()
    |> Pages.get_page_by_url_and_run(run.id)
    |> case do
      nil ->
        start_scrap(run, current_page_url, previous_page_id)

      existing_page = %Page{} ->
        # Page already processed in this run, just save the link
        Logger.info(
          "Page already processed, saving link: run_id=#{run.id} page_url=#{current_page_url}"
        )

        Pages.create_link!(%{page_id: previous_page_id, linked_page_id: existing_page.id})
    end
  end

  defp start_scrap(run = %Run{}, current_page_url, previous_page_id) do
    Logger.info("Starting to scrap a page: run_id=#{run.id} page_url=#{current_page_url}")
    base_url = get_base_url(run.url)

    case scrap_page(run, current_page_url, previous_page_id) do
      {:ok, page, links} ->
        Enum.each(links, fn link ->
          process_page(
            run,
            base_url <> "/" <> String.trim(link, "/") <> "/",
            page.id
          )
        end)

      {:error, reason} ->
        Logger.error(
          "Error when scraping page: run_id=#{run.id} page_url=#{current_page_url} reason=#{inspect(reason)}"
        )
    end
  end

  defp scrap_page(run = %Run{}, current_page_url, previous_page_id) do
    Logger.info("Scrapping page: run_id=#{run.id} page_url=#{current_page_url}")

    current_page_url
    |> Scrapper.scrap()
    |> case do
      {:ok, doc} ->
        title = Scrapper.get_title(doc)
        links = Scrapper.get_relative_links(doc)

        page =
          Pages.create_page!(%{
            url: get_clean_link(current_page_url),
            title: title,
            run_id: run.id
          })

        if !is_nil(previous_page_id) do
          Pages.create_link!(%{page_id: previous_page_id, linked_page_id: page.id})
        end

        {:ok, page, links}

      {:error, reason} ->
        {:error, reason}
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
