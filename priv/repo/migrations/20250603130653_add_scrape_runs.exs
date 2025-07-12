defmodule Scraphex.Repo.Migrations.AddScrapRun do
  use Ecto.Migration

  def change do
    create table(:scrap_runs, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :url, :text, null: false
      add :status, :string, null: false
      add :max_depth, :integer, default: 30, null: false
      add :max_pages, :integer, default: 100, null: false
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
