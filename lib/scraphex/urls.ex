defmodule Scraphex.Urls do
  @doc """
  Get base URL from a given URL.
  """
  def base_url(url) do
    %URI{scheme: scheme, host: host} = URI.parse(url)
    "#{scheme}://#{host}"
  end

  @doc """
  Get a clean link from a given URL.
  """
  def clean_link(href) do
    href
    |> URI.parse()
    |> Map.put(:query, nil)
    |> Map.put(:fragment, nil)
    |> URI.to_string()
  end

  @doc """
  Check if a given URL is relative.
  """
  def relative_link?(href) do
    case {href, URI.parse(href)} do
      # Empty or just fragment
      {"", _} -> false
      {"#" <> _, _} -> false
      # Has scheme (absolute URLs)
      {_, %URI{scheme: scheme}} when is_binary(scheme) -> false
      # Protocol-relative URLs (//example.com)
      {_, %URI{scheme: nil, host: host}} when is_binary(host) -> false
      # Relative URLs
      {_, %URI{scheme: nil, host: nil}} -> true
    end
  end

  @doc """
  Build absolute url from base url and relative link.
  """
  def build_absolute_url(base_url, relative_link) do
    base_uri = URI.parse(base_url)
    relative_uri = URI.parse(relative_link)

    base_uri
    |> URI.merge(relative_uri)
    |> URI.to_string()
  end
end
