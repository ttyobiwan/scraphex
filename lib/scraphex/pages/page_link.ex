defmodule Scraphex.Pages.PageLink do
  use Ecto.Schema
  import Ecto.Changeset

  @foreign_key_type Ecto.UUID
  schema "scrap_page_links" do
    belongs_to :page, Scraphex.Pages.Page
    belongs_to :linked_page, Scraphex.Pages.Page
  end

  def changeset(page, attrs) do
    page
    |> cast(attrs, [:page_id, :linked_page_id])
    |> validate_required([:page_id, :linked_page_id])
    |> unique_constraint([:page_id, :linked_page_id])
  end
end
