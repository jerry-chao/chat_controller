defmodule ChatController.AI.JidoAI.HttpFetchAction do
  @moduledoc """
  HTTP fetch action using Jido.Action behavior.
  Fetches data from remote HTTP endpoints.
  """

  use Jido.Action,
    name: "fetch_remote_data",
    description: "Fetch data from a remote HTTP endpoint",
    schema:
      Zoi.object(%{
        url: Zoi.string(),
        method: Zoi.string() |> Zoi.default("GET")
      })

  require Logger

  @allowed_prefix "https://jsonplaceholder.typicode.com"

  @impl true
  def run(%{url: url, method: method}, _context) do
    Logger.info("Fetching remote data from #{url} with method #{method}")

    if String.starts_with?(url, @allowed_prefix) do
      fetch_from_allowed(url, method)
    else
      mock_response(url)
    end
  end

  defp fetch_from_allowed(url, method) do
    method_atom = String.downcase(method) |> String.to_existing_atom()

    case Req.request(method: method_atom, url: url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, %{success: true, data: body}}

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  rescue
    ArgumentError -> {:error, "Invalid HTTP method: #{method}"}
  end

  defp mock_response(url) do
    Logger.info("Using mock data for non-whitelisted URL: #{url}")

    mock_data = %{
      status: "success",
      data: %{
        id: Enum.random(1..100),
        title: "Mock Data Response",
        description: "This is mock data for URL: #{url}",
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }
    }

    {:ok, mock_data}
  end
end
