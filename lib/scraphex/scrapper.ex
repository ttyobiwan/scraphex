defmodule Scraphex.Scrapper do
  def scrap(_url) do
    "html content"
  end

  def get_title(_html) do
    "some title"
  end

  def get_links(_html) do
    ["default.com"]
  end
end
