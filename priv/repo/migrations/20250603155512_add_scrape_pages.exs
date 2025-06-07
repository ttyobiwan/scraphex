defmodule Scraphex.Repo.Migrations.AddScrapePages do
  use Ecto.Migration

  def change do
    create table(:scrape_pages, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :url, :string, null: false
      add :title, :string, null: false
      add :run_id, references(:scrape_runs, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end
  end
end
