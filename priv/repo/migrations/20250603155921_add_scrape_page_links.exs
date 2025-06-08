defmodule Scraphex.Repo.Migrations.AddScrapPageLinks do
  use Ecto.Migration

  def change do
    create table(:scrap_page_links) do
      add :page_id, references(:scrap_pages, on_delete: :delete_all, type: :binary_id)
      add :linked_page_id, references(:scrap_pages, on_delete: :delete_all, type: :binary_id)
    end
  end
end
