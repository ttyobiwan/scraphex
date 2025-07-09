defmodule Scraphex.Runs.SchedulerTest do
  import Mox
  import Scraphex.RunFixtures
  alias Scraphex.Pages.Page
  alias Scraphex.Runs.Scheduler
  alias Scraphex.Runs

  # Can't be async because of mox_global
  use Scraphex.DataCase

  setup [:verify_on_exit!, :set_mox_global]

  describe "start_run/1" do
    test "processes a run successfully" do
      run = run_fixture(%{url: "http://example.com"})

      expect(Scraphex.HttpClientMock, :get, 2, fn url, _opts ->
        case url do
          "http://example.com/" ->
            {:ok,
             %{
               status: 200,
               body: "<html><title>Home</title><a href='/page1'>Link</a></html>",
               final_url: "http://example.com/"
             }}

          "http://example.com/page1/" ->
            {:ok,
             %{
               status: 200,
               body: "<html><title>Page1</title></html>",
               final_url: "http://example.com/page1/"
             }}
        end
      end)

      Scheduler.start_run(run)

      Process.sleep(100)

      updated_run = Runs.get_run(run.id)
      assert updated_run.status == :completed
    end

    test "handles root page failure" do
      run = run_fixture(%{url: "http://example.com"})

      expect(Scraphex.HttpClientMock, :get, fn _url, _opts ->
        {:ok, %{status: 404, final_url: "http://example.com/"}}
      end)

      Scheduler.start_run(run)

      Process.sleep(100)

      updated_run = Runs.get_run(run.id)
      assert updated_run.status == :completed
    end

    test "respects max depth limit" do
      run = run_fixture(%{url: "http://example.com"})

      Scraphex.HttpClientMock
      |> expect(:get, 30, fn url, _opts ->
        case url do
          "http://example.com/" ->
            {:ok,
             %{
               status: 200,
               body: "<html><title>Deep</title><a href='/deeper/1'>Link</a></html>",
               final_url: "http://example.com/"
             }}

          url ->
            case Regex.run(~r|/deeper/(\d+)/?$|, url) do
              [_, id_str] ->
                id = String.to_integer(id_str)
                next_id = id + 1

                {:ok,
                 %{
                   status: 200,
                   body: "<html><title>Deep</title><a href='/deeper/#{next_id}'>Link</a></html>",
                   final_url: url
                 }}

              _ ->
                {:ok,
                 %{
                   status: 200,
                   body: "<html><title>Deep</title><a href='/deeper/1'>Link</a></html>",
                   final_url: url
                 }}
            end
        end
      end)

      Scheduler.start_run(run)

      Process.sleep(100)

      updated_run = Runs.get_run(run.id)
      assert updated_run.status == :completed
    end

    test "respects max pages limit" do
      run = run_fixture(%{url: "http://example.com"})

      many_links =
        1..105 |> Enum.map(fn i -> "<a href='/page#{i}'>Link #{i}</a>" end) |> Enum.join()

      Scraphex.HttpClientMock
      |> expect(:get, 100, fn url, _opts ->
        {:ok,
         %{
           status: 200,
           body: "<html><title>Many Links</title>#{many_links}</html>",
           final_url: url
         }}
      end)

      Scheduler.start_run(run)

      Process.sleep(150)

      updated_run = Runs.get_run(run.id)
      assert updated_run.status == :completed
    end

    test "skips duplicates" do
      run = run_fixture(%{url: "http://example.com"})

      expect(Scraphex.HttpClientMock, :get, 2, fn url, _opts ->
        case url do
          "http://example.com/" ->
            {:ok,
             %{
               status: 200,
               body: """
               <html>
                 <title>Home</title>
                 <a href='/page1'>Link 1</a>
                 <a href='/page1'>Duplicate Link 1</a>
                 <a href='/page1/'>Link 1 with trailing slash</a>
               </html>
               """,
               final_url: "http://example.com/"
             }}

          "http://example.com/page1/" ->
            {:ok,
             %{
               status: 200,
               body: """
               <html>
                 <title>Page1</title>
                 <a href='/'>Back to home</a>
                 <a href='/page1'>Self reference</a>
               </html>
               """,
               final_url: "http://example.com/page1/"
             }}
        end
      end)

      Scheduler.start_run(run)

      Process.sleep(100)

      updated_run = Runs.get_run(run.id)
      assert updated_run.status == :completed

      pages = Repo.all(from p in Page, where: p.run_id == ^run.id)
      assert length(pages) == 2

      urls = Enum.map(pages, & &1.url) |> Enum.sort()
      assert urls == ["http://example.com/", "http://example.com/page1/"]
    end
  end
end
