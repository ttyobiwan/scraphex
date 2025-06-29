defmodule Scraphex.Runs do
  alias Scraphex.Runs.Scheduler
  alias Scraphex.Runs.Run
  alias Scraphex.Repo
  import Ecto.Query

  @doc """
  Creates a new run object and schedules the start of the scraping process.
  """
  def start_run(url) do
    %{url: url}
    |> create_run!()
    |> Scheduler.start_run()
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

  @doc """
  Gets all runs in a desc order.
  """
  def get_all() do
    Repo.all(from r in Run, order_by: [desc: r.inserted_at])
  end
end
