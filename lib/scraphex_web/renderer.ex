defmodule ScraphexWeb.Renderer do
  require EEx

  EEx.function_from_file(
    :defp,
    :root_layout,
    "lib/scraphex_web/templates/root.html.eex",
    [:assigns]
  )

  EEx.function_from_file(
    :defp,
    :homepage_template,
    "lib/scraphex_web/templates/home.html.eex",
    [:assigns]
  )

  EEx.function_from_file(
    :defp,
    :not_found_template,
    "lib/scraphex_web/templates/404.html.eex"
  )

  def home(runs, messages \\ []) do
    root_layout(%{
      title: "Scraphex | Runs",
      content: homepage_template(%{runs: runs, messages: messages})
    })
  end

  def not_found do
    root_layout(%{
      title: "Scraphex | Not Found",
      content: not_found_template()
    })
  end
end
