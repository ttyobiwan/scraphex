defmodule ScraphexWeb.Router do
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

    Runs.start_run(url)

    runs = Runs.get_all()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, Renderer.home(runs))
  end

  match _ do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(404, Renderer.not_found())
  end
end
