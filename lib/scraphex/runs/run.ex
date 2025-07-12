defmodule Scraphex.Runs.Run do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [:id, :url, :status, :max_depth, :max_pages, :started_at, :completed_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "scrap_runs" do
    field :url, :string
    field :status, Ecto.Enum, values: [:created, :started, :completed], default: :created
    field :max_depth, :integer, default: 30
    field :max_pages, :integer, default: 100

    has_many :pages, Scraphex.Pages.Page

    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [:url, :status, :max_depth, :max_pages])
    |> validate_required([:url])
    |> validate_number(:max_depth, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:max_pages, greater_than: 0, less_than_or_equal_to: 10000)
  end

  def status_changeset(run, attrs) do
    run
    |> cast(attrs, [:status, :started_at, :completed_at])
    |> validate_required([:status])
  end
end
