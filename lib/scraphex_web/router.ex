defmodule ScraphexWeb.Router do
  use Plug.Router

  plug(Plug.Logger)

  plug(Plug.Static,
    at: "/css",
    from: {:scraphex, "priv/static/css"},
    gzip: false
  )

  plug(Plug.Parsers, parsers: [:urlencoded])

  plug(:match)
  plug(:dispatch)

  get "/" do
    html = """
    <!doctype html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <link href="/css/app.css" rel="stylesheet">
      <title>Scraphex | Runs</title>
    </head>
    <form action="/submit" method="post">
      <input type="url" name="url" placeholder="URL" required>
      <button type="submit">Submit</button>
    </form>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  post "/" do
    %{"url" => url} = conn.body_params

    html = """
    <p>URL: #{url}</p>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
