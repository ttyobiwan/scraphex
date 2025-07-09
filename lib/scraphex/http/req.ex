defmodule Scraphex.Http.Req do
  @behaviour Scraphex.Http.Client

  @base_client Req.new()
               |> Req.Request.register_options([:track_redirected])
               |> Req.Request.prepend_response_steps(
                 track_redirected: &__MODULE__.track_redirected_uri/1
               )

  def get(url, opts) do
    req = Req.Request.merge_options(@base_client, opts)

    case Req.get(req, url: url) do
      {:ok, response} ->
        final_url = get_final_url(response, url)
        {:ok, %{status: response.status, body: response.body, final_url: final_url}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def track_redirected_uri({request, response}) do
    {request, put_in(response.private[:final_url], request.url)}
  end

  defp get_final_url(response, original_url) do
    # Check if there's a final URL in the response private data
    case response.private[:final_url] do
      nil -> original_url
      final_url -> URI.to_string(final_url)
    end
  end
end
