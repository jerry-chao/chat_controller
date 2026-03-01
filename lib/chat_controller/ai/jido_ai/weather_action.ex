defmodule ChatController.AI.JidoAI.WeatherAction do
  @moduledoc """
  Weather action using Jido.Action behavior.
  Returns mock weather data for any city.
  """

  use Jido.Action,
    name: "get_weather",
    description: "Get weather information for a city",
    schema:
      Zoi.object(%{
        city: Zoi.string()
      })

  require Logger

  @impl true
  def run(%{city: city}, _context) do
    Logger.info("Getting weather for #{city}")

    weather_data = %{
      city: city,
      temperature: Enum.random(15..30),
      condition: Enum.random(["sunny", "cloudy", "rainy", "partly cloudy"]),
      humidity: Enum.random(40..80),
      wind_speed: Enum.random(5..25)
    }

    {:ok, weather_data}
  end
end
