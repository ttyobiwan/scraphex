defmodule Scraphex.Runs.Run do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "scrape_runs" do
    field :url, :string
    field :status, Ecto.Enum, values: [:created, :started, :completed], default: :created

    timestamps(type: :utc_datetime)
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [:url, :status])
    |> validate_required([:url])
  end

  def status_changeset(run, status) do
    change(run, %{status: status})
  end
end
