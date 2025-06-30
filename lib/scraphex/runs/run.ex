defmodule Scraphex.Runs.Run do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :url, :status, :started_at, :completed_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "scrap_runs" do
    field :url, :string
    field :status, Ecto.Enum, values: [:created, :started, :completed], default: :created

    has_many :pages, Scraphex.Pages.Page

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
