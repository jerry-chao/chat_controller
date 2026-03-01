defmodule ChatController.AI.Tools do
  @moduledoc """
  ReqLLM tools for ChatController AI functionality.
  Includes HTTP-based tools for fetching remote data.
  """

  require Logger

  @doc """
  Returns all available tools for the ChatAgent.
  """
  def all do
    [
      get_weather_tool(),
      get_user_info_tool(),
      fetch_remote_data_tool()
    ]
  end

  @doc """
  Creates the get_weather tool (mock data).
  """
  def get_weather_tool do
    {:ok, tool} =
      ReqLLM.Tool.new(
        name: "get_weather",
        description: "Get weather information for a city",
        parameter_schema: [
          city: [
            type: :string,
            required: true,
            doc: "City name to get weather for"
          ]
        ],
        callback: &get_weather_callback/1
      )

    tool
  end

  defp get_weather_callback(params) do
    city = Map.get(params, :city) || Map.get(params, "city")

    # Mock weather data
    weather_data = %{
      city: city,
      temperature: Enum.random(15..30),
      condition: Enum.random(["sunny", "cloudy", "rainy", "partly cloudy"]),
      humidity: Enum.random(40..80),
      wind_speed: Enum.random(5..25)
    }

    Logger.info("Getting weather for #{city}: #{inspect(weather_data)}")

    {:ok, weather_data}
  end

  @doc """
  Creates the get_user_info tool (mock data).
  """
  def get_user_info_tool do
    {:ok, tool} =
      ReqLLM.Tool.new(
        name: "get_user_info",
        description: "Get user information by user ID",
        parameter_schema: [
          user_id: [
            type: :integer,
            required: true,
            doc: "User ID to fetch information for"
          ]
        ],
        callback: &get_user_info_callback/1
      )

    tool
  end

  defp get_user_info_callback(params) do
    user_id = Map.get(params, :user_id) || Map.get(params, "user_id")

    # Mock user data
    user_data = %{
      id: user_id,
      name: "User #{user_id}",
      email: "user#{user_id}@example.com",
      role: Enum.random(["admin", "user", "moderator"]),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Logger.info("Getting user info for ID #{user_id}: #{inspect(user_data)}")

    {:ok, user_data}
  end

  @doc """
  Creates the fetch_remote_data tool with actual HTTP capabilities.
  """
  def fetch_remote_data_tool do
    {:ok, tool} =
      ReqLLM.Tool.new(
        name: "fetch_remote_data",
        description: "Fetch data from a remote HTTP endpoint",
        parameter_schema: [
          url: [
            type: :string,
            required: true,
            doc:
              "URL to fetch data from (supports https://jsonplaceholder.typicode.com endpoints)"
          ],
          method: [
            type: :string,
            required: false,
            doc: "HTTP method (GET, POST, etc. - default: GET)"
          ]
        ],
        callback: &fetch_remote_data_callback/1
      )

    tool
  end

  defp fetch_remote_data_callback(params) do
    url = Map.get(params, :url) || Map.get(params, "url")
    method = Map.get(params, :method) || Map.get(params, "method", "GET")

    # For security, only allow specific safe endpoints (mock API)
    if String.starts_with?(url, "https://jsonplaceholder.typicode.com") do
      Logger.info("Fetching remote data from #{url} with method #{method}")

      case fetch_http_data(url, method) do
        {:ok, data} ->
          {:ok, %{success: true, data: data}}

        {:error, reason} ->
          {:error, "Failed to fetch data: #{inspect(reason)}"}
      end
    else
      # Return mock data for non-whitelisted URLs
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

  defp fetch_http_data(url, method) do
    method_atom = String.downcase(method) |> String.to_atom()

    case Req.request(method: method_atom, url: url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
