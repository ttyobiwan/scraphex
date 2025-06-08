defmodule Scraphex.Repo.Migrations.AddScrapPages do
  use Ecto.Migration

  def change do
    create table(:scrap_pages, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :url, :text, null: false
      add :title, :text, null: false
      add :run_id, references(:scrap_runs, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end
  end
end
