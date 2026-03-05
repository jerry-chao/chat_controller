defmodule ChatController.AI.LangChain.Tools.Weather do
  @moduledoc """
  Weather tool using LangChain.Function.
  Returns mock weather data for any city.
  """

  require Logger

  @doc """
  Returns the weather tool function definition for LangChain.
  """
  def function do
    %{
      name: "get_weather",
      description: "Get weather information for a city",
      parameters_schema: %{
        type: "object",
        properties: %{
          city: %{
            type: "string",
            description: "The city name to get weather for"
          }
        },
        required: ["city"]
      },
      function: &execute/2
    }
  end

  @doc """
  Executes the weather lookup.
  """
  def execute(args, _context) do
    city = Map.get(args, "city") || Map.get(args, :city)
    Logger.info("Getting weather for #{city}")

    weather_data = %{
      city: city,
      temperature: Enum.random(15..30),
      condition: Enum.random(["sunny", "cloudy", "rainy", "partly cloudy"]),
      humidity: Enum.random(40..80),
      wind_speed: Enum.random(5..25)
    }

    Jason.encode!(weather_data)
  end
end
