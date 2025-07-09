defmodule Scraphex.Scrapper do
  alias Scraphex.Urls

  @doc """
  Scraps a page and parses it into document.
  """
  def scrap(url, http_client \\ nil) do
    http_client = http_client || Application.get_env(:scraphex, :http_client, Scraphex.Http.Req)

    case http_client.get(url,
           headers: [{"user-agent", "Mozilla/5.0 (compatible; Scraphex/1.0)"}]
         ) do
      {:ok, %{status: 200, body: body, final_url: final_url}} ->
        {:ok, Floki.parse_document!(body), final_url}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets a title from a parsed doc.
  """
  def get_title(doc) do
    doc
    |> Floki.find("title")
    |> Floki.text()
  end

  @doc """
  Get all relative links from the doc.
  """
  def get_relative_links(doc) do
    doc
    |> Floki.find("a[href]")
    |> Floki.attribute("href")
    |> Enum.filter(fn href -> Urls.relative_link?(href) end)
    |> Enum.map(&Urls.normalize_path/1)
    |> Enum.uniq()
  end
end
