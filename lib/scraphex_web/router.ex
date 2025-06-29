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
    only: ~w(favicon.ico css fonts)
  )

  plug(Plug.Parsers, parsers: [:urlencoded])

  plug(:match)
  plug(:dispatch)

  get "/" do
    runs = Runs.get_all()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Renderer.home(runs))
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

    runs = Runs.get_all()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Renderer.home(runs, [message]))
  end

  match _ do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(404, Renderer.not_found())
  end
end
