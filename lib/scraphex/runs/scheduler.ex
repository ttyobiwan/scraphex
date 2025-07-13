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
    |> case do
      {:ok, run} ->
        Runs.mark_run_as_finished!(run, :successful)

      {:error, {run, :stopped}} ->
        Runs.mark_run_as_finished!(run, :stopped)

      {:error, {run, reason}} ->
        Logger.error("Processing run failed: #{inspect(reason)}")
        Runs.mark_run_as_finished!(run, :failed)
    end

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
      total_processed: 0,
      stopped: false
    }

    case process_root_page(state) do
      {:ok, state, {page, links}} ->
        state = process_links(state, page, prepare_links(state, page, links))

        Logger.info("Done processing run: #{run.id}")

        if state.stopped == true do
          {:error, {run, :stopped}}
        else
          {:ok, run}
        end

      {:error, reason} ->
        {:error, {run, reason}}
    end
  end

  defp process_root_page(state = %State{}) do
    root_url = Urls.build_absolute_url(state.base_url, "/")

    Logger.info("Starting to process root page: #{root_url}")

    case Worker.process_page(root_url, state.run.id) do
      {:ok, page, links} ->
        Logger.info("Processed root page, found #{length(links)} links: #{links}")

        # Update base URL if root page was redirected
        state =
          case page.url do
            ^root_url ->
              state

            final_url ->
              Logger.info("Root page redirected from #{root_url} to #{final_url}")
              Map.put(state, :base_url, Urls.base_url(final_url))
          end

        {:ok, update_state(state, ["/"]), {page, links}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp process_links(state = %State{}, page = %Page{}, []) do
    Logger.debug("No more links to process: page_url=#{page.url}")
    state
  end

  defp process_links(state = %State{}, page = %Page{}, links) do
    Logger.info(
      "Processing links: page_url=#{page.url} links=#{length(links)} depth=#{state.depth} total_processed=#{state.total_processed}"
    )

    cond do
      state.stopped ->
        state

      state.depth >= state.run.max_depth ->
        Logger.info("Max depth reached (#{state.run.max_depth}), stopping crawl")
        Map.put(state, :stopped, true)

      state.total_processed >= state.run.max_pages ->
        Logger.info("Max pages reached (#{state.run.max_pages}), stopping crawl")
        Map.put(state, :stopped, true)

      true ->
        # If we took the max amount of links, means we have to stop after processing
        # It's a little hacky to do this here, but works well
        state =
          if length(links) == state.run.max_pages - state.total_processed do
            Map.put(state, :stopped, true)
          else
            state
          end

        do_process_links(state, page, links)
    end
  end

  defp prepare_links(state = %State{}, page = %Page{}, links) do
    Logger.debug("Preparing links: #{page.url} #{links}")

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
        Logger.debug("Found already visited links: #{page.url}, #{visited_links}")

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
      if acc_state.stopped do
        acc_state
      else
        process_links(acc_state, new_page, prepare_links(acc_state, new_page, new_links))
      end
    end)
  end

  defp update_state(state = %State{}, links) do
    state
    |> Map.put(:visited, Enum.into(links, state.visited))
    |> Map.put(:depth, state.depth + 1)
    |> Map.put(:total_processed, state.total_processed + length(links))
  end
end
