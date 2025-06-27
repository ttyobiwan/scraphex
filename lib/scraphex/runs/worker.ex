defmodule Scraphex.Runs.Worker do
  alias Scraphex.Pages
  alias Scraphex.Scrapper
  alias Scraphex.Urls
  require Logger

  @doc """
  Process a single page.
  """
  def process_page(url, run_id) do
    Logger.info("Processing a page: #{url}")

    url
    |> Scrapper.scrap()
    |> case do
      {:ok, doc} ->
        title = Scrapper.get_title(doc)
        links = Scrapper.get_relative_links(doc)

        page =
          Pages.create_page!(%{
            url: Urls.clean_link(url),
            title: title,
            run_id: run_id
          })

        {:ok, page, links}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Process multiple pages asynchronously.
  """
  def process_many_pages(urls, run_id) do
    Logger.info("Starting to process multiple urls: #{urls}")

    results =
      __MODULE__
      |> Task.Supervisor.async_stream(urls, fn url -> process_page(url, run_id) end)
      |> Enum.reduce([], fn
        {:ok, {:ok, page, links}}, acc ->
          [{:ok, page, links} | acc]

        {:ok, {:error, reason}}, acc ->
          Logger.error("Failed to process page: #{inspect(reason)}")
          [{:error, reason} | acc]

        {:exit, reason}, acc ->
          Logger.error("Task exited with reason: #{inspect(reason)}")
          [{:error, {:task_exit, reason}} | acc]
      end)
      |> Enum.reverse()

    {successes, errors} = Enum.split_with(results, &match?({:ok, _, _}, &1))

    Logger.info(
      "Processed #{length(urls)} URLs: #{length(successes)} successes, #{length(errors)} errors"
    )

    Enum.map(successes, fn {:ok, page, links} -> {page, links} end)
  end

  @doc """
  Save connections between pages.
  """
  def save_page_connections(page, pages) do
    Pages.create_links(page, pages)
  end

  @doc """
  Save connections between page and links.
  This assumes that passed links are already saved as pages.
  """
  def save_link_connections(page, links, run) do
    links
    |> Pages.get_pages_by_urls_and_run(run.id)
    |> tap(fn pages -> Pages.create_links(page, pages) end)
  end

  def start_link(opts \\ []) do
    Logger.info("Starting runs worker")
    Task.Supervisor.start_link([name: __MODULE__] ++ opts)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end
end
