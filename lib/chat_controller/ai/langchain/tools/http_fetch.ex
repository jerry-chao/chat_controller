defmodule ChatController.AI.LangChain.Tools.HttpFetch do
  @moduledoc """
  HTTP fetch tool using LangChain.Function.
  Fetches data from remote HTTP endpoints.
  """

  require Logger

  @allowed_prefix "https://jsonplaceholder.typicode.com"

  @doc """
  Returns the HTTP fetch tool function definition for LangChain.
  """
  def function do
    %{
      name: "fetch_remote_data",
      description: "Fetch data from a remote HTTP endpoint",
      parameters_schema: %{
        type: "object",
        properties: %{
          url: %{
            type: "string",
            description: "The URL to fetch data from"
          },
          method: %{
            type: "string",
            description: "HTTP method (GET, POST, etc.)",
            default: "GET"
          }
        },
        required: ["url"]
      },
      function: &execute/2
    }
  end

  @doc """
  Executes the HTTP fetch.
  """
  def execute(args, _context) do
    url = Map.get(args, "url") || Map.get(args, :url)
    method = Map.get(args, "method") || Map.get(args, :method, "GET")

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
        Jason.encode!(%{success: true, data: body})

      {:ok, %Req.Response{status: status}} ->
        Jason.encode!(%{success: false, error: "HTTP #{status}"})

      {:error, reason} ->
        Jason.encode!(%{success: false, error: "Request failed: #{inspect(reason)}"})
    end
  rescue
    ArgumentError ->
      Jason.encode!(%{success: false, error: "Invalid HTTP method: #{method}"})
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

    Jason.encode!(mock_data)
  end
end
