defmodule Scraphex.Runs.Scheduler do
  alias Scraphex.Pages.Page
  alias Scraphex.Runs.State
  alias Scraphex.Runs.Worker
  alias Scraphex.Urls
  alias Scraphex.Runs
  alias Scraphex.Runs.Run
  require Logger

  use GenServer

  @doc """
  Schedules start of a run.
  """
  def start_run(run = %Run{}, notify_pid \\ nil) do
    GenServer.cast(__MODULE__, {:start, run, notify_pid})
  end

  def start_link(init_arg) do
    Logger.info("Starting runs scheduler")
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    {:ok, []}
  end

  def handle_cast({:start, run = %Run{}, notify_pid}, state) do
    run
    |> Runs.mark_run_as_started!()
    |> process_run()
    |> Runs.mark_run_as_completed!()

    if notify_pid do
      send(notify_pid, {:run_completed, run.id})
    end

    {:noreply, state}
  end

  defp process_run(run = %Run{}) do
    Logger.info("Starting to process run: #{run.id}")

    state = %State{
      run: run,
      base_url: Urls.base_url(run.url),
      visited: MapSet.new(),
      depth: 0,
      total_processed: 0
    }

    # Process the root page
    root_url = Urls.build_absolute_url(state.base_url, "/")
    Logger.info("Processing root page: #{root_url}")

    case Worker.process_page(root_url, run.id) do
      {:ok, page, links} ->
        Logger.info("Successfully processed root page, found #{length(links)} links")

        # Update base URL if root page was redirected
        updated_state =
          case page.url do
            ^root_url ->
              state

            final_url ->
              Logger.info("Root page redirected from #{root_url} to #{final_url}")
              Map.put(state, :base_url, Urls.base_url(final_url))
          end

        final_state =
          updated_state
          |> update_state(["/"])
          |> process_links(page, links)

        Logger.info(
          "Done processing all links: total_processed=#{final_state.total_processed}, final_depth=#{final_state.depth}"
        )

      {:error, reason} ->
        Logger.error("Failed to process root page: #{inspect(reason)}")
        Logger.info("Stopping crawl due to root page failure")
    end

    run
  end

  defp process_links(state = %State{}, page = %Page{}, []) do
    Logger.info("No more links to process: page_url=#{page.url}")
    state
  end

  defp process_links(state = %State{}, page = %Page{}, links) do
    Logger.info(
      "Processing links: page_url=#{page.url} links=#{length(links)} depth=#{state.depth} total_processed=#{state.total_processed}"
    )

    # Check limits
    cond do
      state.depth >= state.run.max_depth ->
        Logger.info("Max depth reached (#{state.run.max_depth}), stopping crawl")
        state

      state.total_processed >= state.run.max_pages ->
        Logger.info("Max pages reached (#{state.run.max_pages}), stopping crawl")
        state

      true ->
        do_process_links(state, page, prepare_links(state, page, links))
    end
  end

  defp prepare_links(state = %State{}, page = %Page{}, links) do
    Logger.info("Preparing links for page: #{page.url}, #{links}")
    # Normalize and deduplicate links
    normalized_links =
      links
      |> Enum.map(&Urls.normalize_path/1)
      |> Enum.uniq()

    # For each already visited link, just create a connection
    normalized_links
    |> Enum.filter(fn link ->
      MapSet.member?(state.visited, link)
    end)
    |> case do
      [] ->
        nil

      visited_links ->
        Logger.info("Found already visited links: #{page.url}, #{visited_links}")

        Worker.save_link_connections(
          page,
          Enum.map(visited_links, fn link -> Urls.build_absolute_url(state.base_url, link) end),
          state.run
        )
    end

    # Remove already visited links
    new_links =
      Enum.reject(normalized_links, fn link ->
        MapSet.member?(state.visited, link)
      end)

    Enum.take(new_links, state.run.max_pages - state.total_processed)
  end

  defp do_process_links(state = %State{}, page = %Page{}, []) do
    # If no new links or limits reached, return current state
    Logger.info("No new links to process for page: #{page.url}")
    state
  end

  defp do_process_links(state = %State{}, page = %Page{}, links) do
    Logger.info("Processing #{length(links)} new links from page: #{page.url}")

    absolute_urls =
      Enum.map(links, fn link ->
        Urls.build_absolute_url(state.base_url, link)
      end)

    results = Worker.process_many_pages(absolute_urls, state.run.id)

    pages = Enum.map(results, fn {page, _links} -> page end)

    # Create connections from current page to new pages
    unless Enum.empty?(pages) do
      Worker.save_page_connections(page, pages)
    end

    updated_state = update_state(state, links)

    # Process each result recursively and accumulate state
    Enum.reduce(results, updated_state, fn {new_page, new_links}, acc_state ->
      process_links(acc_state, new_page, prepare_links(acc_state, new_page, new_links))
    end)
  end

  defp update_state(state = %State{}, links) do
    state
    |> Map.put(:visited, Enum.into(links, state.visited))
    |> Map.put(:depth, state.depth + 1)
    |> Map.put(:total_processed, state.total_processed + length(links))
  end
end
