defmodule Scraphex.Runs do
  alias Scraphex.Runs.Worker
  alias Scraphex.Runs.Run
  alias Scraphex.Repo

  @doc """
  Creates a new run object and schedules the start of the scraping process.
  """
  def start_run(url) do
    run = create_run!(%{url: url})
    Worker.start_run(run)
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
end
