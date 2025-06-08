defmodule Scraphex.Runs.Run do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "scrap_runs" do
    field :url, :string
    field :status, Ecto.Enum, values: [:created, :started, :completed], default: :created

    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [:url, :status])
    |> validate_required([:url])
  end

  def status_changeset(run, attrs) do
    run
    |> cast(attrs, [:status, :started_at, :completed_at])
    |> validate_required([:status])
  end
end
