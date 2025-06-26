defmodule Scraphex.Runs.Scheduler do
  alias Scraphex.Runs.Worker
  alias Scraphex.Urls
  alias Scraphex.Runs
  alias Scraphex.Runs.Run
  require Logger

  use GenServer

  @doc """
  Schedules start of a run.
  """
  def start_run(run = %Run{}) do
    GenServer.cast(__MODULE__, {:start, run})
  end

  def start_link(init_arg) do
    Logger.info("Starting runs scheduler")
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    {:ok, []}
  end

  def handle_cast({:start, run = %Run{}}, state) do
    run
    |> Runs.mark_run_as_started!()
    |> process_run()
    |> Runs.mark_run_as_completed!()

    {:noreply, state}
  end

  defp process_run(run = %Run{}) do
    Logger.info("Starting to process run: #{run.id}")

    state = %{
      run: run,
      base_url: Urls.base_url(run.url),
      visited: MapSet.new(),
      depth: 0,
      total_processed: 0
    }

    # Process the root page
    {:ok, page, links} = Worker.process_page(Urls.build_absolute_url(state.base_url, "/"), run.id)

    final_state =
      state
      |> update_state(["/"])
      |> process_links(page, links)

    Logger.info("Done processing all links: final_state=#{inspect(final_state)}")

    run
  end

  defp process_links(state, page, []) do
    Logger.info("No more links to process: page_url=#{page.url}")
    state
  end

  defp process_links(state, page, links) do
    Logger.info("Processing links: page_url=#{page.url} links=#{links}")

    # todo: check depth
    # todo: check total processed
    # todo: seems like we are not connecting "/" correctly because visited often have things like "/r/capper" and "/r/capper/"

    # For each already visited link, just create a connection
    links
    |> Enum.uniq()
    |> Enum.filter(fn link -> MapSet.member?(state.visited, link) end)
    |> tap(fn links -> Worker.save_link_connections(page, links, state.run) end)

    # Deduplicate and remove already visited links
    links =
      links
      |> Enum.uniq()
      |> Enum.reject(fn link -> MapSet.member?(state.visited, link) end)

    # todo: what if none left? maybe we could return state early?

    # Then, process them all, and save connections
    results =
      links
      |> Enum.map(fn link -> Urls.build_absolute_url(state.base_url, link) end)
      |> Worker.process_many_pages(state.run.id)

    pages = Enum.map(results, fn {page, _links} -> page end)

    Worker.save_page_connections(page, pages)

    # Update state
    state = update_state(state, links)

    # Process each result and thread state through the recursive calls
    Enum.reduce(results, state, fn {page, links}, acc_state ->
      process_links(acc_state, page, links)
    end)

    state
  end

  defp update_state(state, links) do
    state
    |> Map.put(:visited, Enum.into(links, state.visited))
    |> Map.put(:depth, state.depth + 1)
    |> Map.put(:total_processed, state.total_processed + length(links))
  end
end
