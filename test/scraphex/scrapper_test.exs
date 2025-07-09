defmodule Scraphex.ScrapperTest do
  alias Scraphex.Scrapper
  import Mox

  use ExUnit.Case, async: true

  setup :verify_on_exit!

  describe "scrap/2" do
    test "returns parsed document on successful request" do
      html_body = """
      <html>
        <head><title>Test Page</title></head>
        <body>
          <a href="/page1">Page 1</a>
          <a href="https://external.com">External</a>
        </body>
      </html>
      """

      Scraphex.HttpClientMock
      |> expect(:get, fn _url, _opts ->
        {:ok, %{status: 200, body: html_body, final_url: "https://example.com"}}
      end)

      assert {:ok, doc, final_url} = Scrapper.scrap("https://example.com")
      assert final_url == "https://example.com"

      assert doc == [
               {"html", [],
                [
                  {"head", [], [{"title", [], ["Test Page"]}]},
                  {"body", [],
                   [
                     {"a", [{"href", "/page1"}], ["Page 1"]},
                     {"a", [{"href", "https://external.com"}], ["External"]}
                   ]}
                ]}
             ]
    end

    test "returns http_error for other status codes" do
      Scraphex.HttpClientMock
      |> expect(:get, fn _url, _opts ->
        {:ok, %{status: 500, final_url: "https://example.com"}}
      end)

      assert {:error, {:http_error, 500}} =
               Scrapper.scrap("https://example.com", Scraphex.HttpClientMock)
    end

    test "returns error when request fails" do
      Scraphex.HttpClientMock
      |> expect(:get, fn _url, _opts ->
        {:error, :timeout}
      end)

      assert {:error, :timeout} = Scrapper.scrap("https://example.com", Scraphex.HttpClientMock)
    end

    test "returns final URL after redirect" do
      html_body = """
      <html>
        <head><title>Login Page</title></head>
        <body>
          <form>Login form</form>
        </body>
      </html>
      """

      Scraphex.HttpClientMock
      |> expect(:get, fn _url, _opts ->
        {:ok, %{status: 200, body: html_body, final_url: "https://example.com/login"}}
      end)

      assert {:ok, _doc, final_url} = Scrapper.scrap("https://example.com/protected")
      assert final_url == "https://example.com/login"
    end
  end

  describe "get_title/1" do
    test "extracts title from document" do
      html = "<html><head><title>My Page Title</title></head></html>"
      doc = Floki.parse_document!(html)

      assert Scrapper.get_title(doc) == "My Page Title"
    end

    test "returns empty string when no title" do
      html = "<html><head></head></html>"
      doc = Floki.parse_document!(html)

      assert Scrapper.get_title(doc) == ""
    end
  end

  describe "get_relative_links/1" do
    test "extracts only relative links" do
      html = """
      <html>
        <body>
          <a href="/page1">Page 1</a>
          <a href="/page2">Page 2</a>
          <a href="https://external.com">External</a>
          <a href="mailto:test@example.com">Email</a>
          <a href="../parent">Parent</a>
        </body>
      </html>
      """

      doc = Floki.parse_document!(html)
      links = Scrapper.get_relative_links(doc)

      assert is_list(links)
      assert length(links) == 3
    end

    test "removes duplicates" do
      html = """
      <html>
        <body>
          <a href="/page1">Page 1</a>
          <a href="/page1">Page 1 Again</a>
        </body>
      </html>
      """

      doc = Floki.parse_document!(html)
      links = Scrapper.get_relative_links(doc)

      # Should have only one unique link
      assert length(links) == 1
    end
  end
end
