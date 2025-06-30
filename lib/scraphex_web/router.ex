defmodule ScraphexWeb.Router do
  require Logger
  alias ScraphexWeb.Renderer
  alias Scraphex.Runs
  use Plug.Router

  plug(Plug.Logger)

  plug(Plug.Static,
    at: "/",
    from: :scraphex,
    gzip: false,
    only: ~w(favicon.ico css js fonts)
  )

  plug(Plug.Parsers, parsers: [:urlencoded])

  plug(:match)
  plug(:dispatch)

  get "/" do
    runs = Runs.get_all_runs()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Renderer.home(%{runs: runs}))
  end

  post "/" do
    %{"url" => url} = conn.body_params

    result = Runs.start_run(url)

    message =
      case result do
        {:ok, _run} ->
          %{type: :success, text: "Run scheduled successfully"}

        {:error, changeset} ->
          Logger.error("Failed to schedule run: #{inspect(changeset.errors)}")
          %{type: :error, text: "Failed to schedule run"}
      end

    runs = Runs.get_all_runs()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Renderer.home(%{runs: runs, messages: [message]}))
  end

  get "/runs/:id" do
    %{"id" => id} = conn.params

    case Runs.get_run(id) do
      nil ->
        not_found(conn)

      run ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, Renderer.run_graph(%{run: run}))
    end
  end

  match _ do
    not_found(conn)
  end

  defp not_found(conn) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(404, Renderer.not_found())
  end
end
