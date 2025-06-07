defmodule Scraphex.Repo.Migrations.AddScrapePageLinks do
  use Ecto.Migration

  def change do
    create table(:scrape_page_links) do
      add :page_id, references(:scrape_pages, on_delete: :delete_all, type: :binary_id)
      add :linked_page_id, references(:scrape_pages, on_delete: :delete_all, type: :binary_id)
    end
  end
end
