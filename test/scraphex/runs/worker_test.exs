defmodule Scraphex.Runs.WorkerTest do
  import Mox
  alias Scraphex.Runs.Worker
  import Scraphex.RunFixtures
  import Scraphex.PageFixtures

  use Scraphex.DataCase, async: true

  setup :verify_on_exit!

  describe "process_page/2" do
    test "successfully processes a page" do
      run = run_fixture()

      expect(Scraphex.HttpClientMock, :get, fn _url, _opts ->
        {:ok,
         %{
           status: 200,
           body: "<html>
             <title>Test</title>
             <a href='/page1'>Link</a>
             <a href='/page2'>Link</a>
             </html>"
         }}
      end)

      assert {:ok, page, links} = Worker.process_page("http://scraphex.com/", run.id)
      assert page.title == "Test"
      assert page.url == "http://scraphex.com/"
      assert links == ["/page1/", "/page2/"]
    end

    test "handles HTTP errors" do
      run = run_fixture()

      expect(Scraphex.HttpClientMock, :get, fn _url, _opts ->
        {:ok, %{status: 404}}
      end)

      assert {:error, :not_found} = Worker.process_page("http://scraphex.com/", run.id)
    end
  end

  describe "process_many_pages/2" do
    test "processes multiple pages successfully" do
      run = run_fixture()

      expect(Scraphex.HttpClientMock, :get, 3, fn url, _opts ->
        case url do
          "http://scraphex.com/page1" ->
            {:ok, %{status: 200, body: "<html><title>Page1</title></html>"}}

          "http://scraphex.com/page2" ->
            {:ok, %{status: 200, body: "<html><title>Page2</title></html>"}}

          "http://scraphex.com/page3" ->
            {:ok, %{status: 404}}
        end
      end)

      results =
        Worker.process_many_pages(
          ["http://scraphex.com/page1", "http://scraphex.com/page2", "http://scraphex.com/page3"],
          run.id
        )

      assert length(results) == 2
      assert Enum.all?(results, fn {page, []} -> is_struct(page) end)
    end
  end

  describe "save_page_connections/2" do
    test "creates links between pages" do
      run = run_fixture()
      page1 = page_fixture(%{run_id: run.id})
      page2 = page_fixture(%{run_id: run.id})
      page3 = page_fixture(%{run_id: run.id})

      Worker.save_page_connections(page1, [page2, page3])

      page1 = Repo.preload(page1, :page_links)
      assert length(page1.page_links) == 2
    end
  end

  describe "save_link_connections/3" do
    test "creates connections to existing pages by URLs" do
      run = run_fixture()
      page1 = page_fixture(%{run_id: run.id})
      page2 = page_fixture(%{run_id: run.id, url: "/page2/"})
      page3 = page_fixture(%{run_id: run.id, url: "/page3/"})

      Worker.save_link_connections(page1, ["/page2/", "/page3/"], run)

      page1 = Repo.preload(page1, :page_links)
      linked_page_ids = Enum.map(page1.page_links, fn link -> link.linked_page_id end)
      assert length(linked_page_ids) == 2
      assert Enum.member?(linked_page_ids, page2.id)
      assert Enum.member?(linked_page_ids, page3.id)
    end
  end
end
