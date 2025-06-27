defmodule Scraphex.UrlsTest do
  alias Scraphex.Urls

  use ExUnit.Case, async: true

  describe "base_url/1" do
    test "extracts base URL from complete URL" do
      assert Urls.base_url("https://example.com/path/to/page") == "https://example.com"
    end

    test "extracts base URL with query parameters" do
      assert Urls.base_url("https://example.com/search?q=test") == "https://example.com"
    end

    test "extracts base URL with fragment" do
      assert Urls.base_url("https://example.com/page#section") == "https://example.com"
    end

    test "handles HTTP URLs" do
      assert Urls.base_url("http://example.com/path") == "http://example.com"
    end

    test "handles URLs with port" do
      assert Urls.base_url("https://example.com:8080/path") == "https://example.com"
    end

    test "handles subdomain" do
      assert Urls.base_url("https://api.example.com/v1/users") == "https://api.example.com"
    end
  end

  describe "normalize_path/1" do
    test "adds trailing slash to path without one" do
      assert Urls.normalize_path("/path") == "/path/"
    end

    test "keeps trailing slash if already present" do
      assert Urls.normalize_path("/path/") == "/path/"
    end

    test "handles root path" do
      assert Urls.normalize_path("/") == "/"
    end

    test "handles empty string" do
      assert Urls.normalize_path("") == "/"
    end

    test "handles path with multiple trailing slashes" do
      assert Urls.normalize_path("/path///") == "/path/"
    end

    test "handles relative path" do
      assert Urls.normalize_path("path/to/file") == "path/to/file/"
    end

    test "handles single character path" do
      assert Urls.normalize_path("a") == "a/"
    end
  end

  describe "clean_link/1" do
    test "removes query parameters" do
      assert Urls.clean_link("https://example.com/path?query=value") ==
               "https://example.com/path/"
    end

    test "removes fragment" do
      assert Urls.clean_link("https://example.com/path#section") ==
               "https://example.com/path/"
    end

    test "removes both query and fragment" do
      assert Urls.clean_link("https://example.com/path?query=value#section") ==
               "https://example.com/path/"
    end

    test "normalizes path by adding trailing slash" do
      assert Urls.clean_link("https://example.com/path") ==
               "https://example.com/path/"
    end

    test "handles URL with existing trailing slash" do
      assert Urls.clean_link("https://example.com/path/") ==
               "https://example.com/path/"
    end

    test "handles root path" do
      assert Urls.clean_link("https://example.com") ==
               "https://example.com/"
    end

    test "handles URL with port" do
      assert Urls.clean_link("https://example.com:8080/path?query=value") ==
               "https://example.com:8080/path/"
    end
  end

  describe "relative_link?/1" do
    test "returns false for empty string" do
      refute Urls.relative_link?("")
    end

    test "returns false for fragment-only links" do
      refute Urls.relative_link?("#section")
      refute Urls.relative_link?("#")
    end

    test "returns false for absolute HTTP URLs" do
      refute Urls.relative_link?("http://example.com/path")
    end

    test "returns false for absolute HTTPS URLs" do
      refute Urls.relative_link?("https://example.com/path")
    end

    test "returns false for other schemes" do
      refute Urls.relative_link?("ftp://example.com/file")
      refute Urls.relative_link?("mailto:test@example.com")
    end

    test "returns false for protocol-relative URLs" do
      refute Urls.relative_link?("//example.com/path")
    end

    test "returns true for relative paths starting with slash" do
      assert Urls.relative_link?("/path/to/page")
    end

    test "returns true for relative paths without leading slash" do
      assert Urls.relative_link?("path/to/page")
    end

    test "returns true for current directory reference" do
      assert Urls.relative_link?("./path")
    end

    test "returns true for parent directory reference" do
      assert Urls.relative_link?("../path")
    end

    test "returns true for filename only" do
      assert Urls.relative_link?("file.html")
    end

    test "returns true for query-only relative URLs" do
      assert Urls.relative_link?("?query=value")
    end
  end

  describe "build_absolute_url/2" do
    test "builds absolute URL from base and relative path" do
      base = "https://example.com"
      relative = "/path/to/page"
      expected = "https://example.com/path/to/page"

      assert Urls.build_absolute_url(base, relative) == expected
    end

    test "builds absolute URL with relative path without leading slash" do
      base = "https://example.com/current"
      relative = "page.html"
      expected = "https://example.com/page.html"

      assert Urls.build_absolute_url(base, relative) == expected
    end

    test "handles parent directory references" do
      base = "https://example.com/path/current"
      relative = "../other/page.html"
      expected = "https://example.com/other/page.html"

      assert Urls.build_absolute_url(base, relative) == expected
    end

    test "handles current directory references" do
      base = "https://example.com/path/"
      relative = "./page.html"
      expected = "https://example.com/path/page.html"

      assert Urls.build_absolute_url(base, relative) == expected
    end

    test "preserves query parameters in relative URL" do
      base = "https://example.com"
      relative = "/search?q=test"
      expected = "https://example.com/search?q=test"

      assert Urls.build_absolute_url(base, relative) == expected
    end

    test "preserves fragment in relative URL" do
      base = "https://example.com"
      relative = "/page#section"
      expected = "https://example.com/page#section"

      assert Urls.build_absolute_url(base, relative) == expected
    end

    test "handles base URL with path" do
      base = "https://example.com/base/path"
      relative = "/absolute/path"
      expected = "https://example.com/absolute/path"

      assert Urls.build_absolute_url(base, relative) == expected
    end

    test "replaces absolute relative path" do
      base = "https://example.com/some/deep/path"
      relative = "/root/level"
      expected = "https://example.com/root/level"

      assert Urls.build_absolute_url(base, relative) == expected
    end
  end
end
