defmodule Scraphex.Runs do
  alias Scraphex.Runs.Scheduler
  alias Scraphex.Runs.Run
  alias Scraphex.Repo
  import Ecto.Query

  @doc """
  Creates a new run object and schedules the start of the scraping process.
  """
  def start_run(attrs) do
    case create_run(attrs) do
      {:ok, run} ->
        Scheduler.start_run(run)
        {:ok, run}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Creates a new run object.
  """
  def create_run(attrs \\ %{}) do
    %Run{}
    |> Run.changeset(attrs)
    |> Repo.insert()
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
  Marks run as finished.
  That means it either succeeded, stopped or failed.
  """
  def mark_run_as_finished!(run = %Run{}, status) do
    run
    |> Run.status_changeset(%{status: status, finished_at: DateTime.utc_now()})
    |> Repo.update!()
  end

  @doc """
  Gets all runs in a desc order.
  """
  def get_all_runs() do
    Repo.all(from r in Run, order_by: [desc: r.inserted_at])
  end

  @doc """
  Gets a single run with all its pages and their connections.
  """
  def get_run(id) do
    Run
    |> Repo.get(id)
    |> Repo.preload([:pages, pages: :page_links, pages: :linked_pages])
  end
end
