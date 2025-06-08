defmodule Scraphex.Pages.Page do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "scrap_pages" do
    field :url, :string
    field :title, :string

    belongs_to :run, Scraphex.Runs.Run
    has_many :page_links, Scraphex.Pages.PageLink
    has_many :linked_pages, through: [:page_links, :linked_page]

    timestamps(type: :utc_datetime)
  end

  def changeset(page, attrs) do
    page
    |> cast(attrs, [:url, :title, :run_id])
    |> validate_required([:url, :title, :run_id])
  end
end
