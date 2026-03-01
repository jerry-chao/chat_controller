defmodule ChatController.AI.JidoAI.Agent do
  @moduledoc """
  Chat agent using Jido.AI for tool-calling capabilities.
  Replaces the custom Jido-style orchestration with official jido_ai.
  """

  use Jido.AI.Agent,
    name: "chat_agent",
    description: "AI assistant for ChatController with tool-calling",
    model: :fast,
    tools: [
      ChatController.AI.JidoAI.WeatherAction,
      ChatController.AI.JidoAI.UserInfoAction,
      ChatController.AI.JidoAI.HttpFetchAction
    ],
    system_prompt: """
    You are a helpful AI assistant for ChatController.

    You have access to several tools:
    - get_weather: Get weather information for any city
    - get_user_info: Get user information by user ID
    - fetch_remote_data: Fetch data from remote HTTP endpoints

    When users ask about weather, use the get_weather tool.
    When users ask about user information, use the get_user_info tool.
    When users ask to fetch data from a URL, use the fetch_remote_data tool.

    Always explain the results in clear, user-friendly language.
    Be helpful, friendly, and concise in your responses.
    """

  @doc """
  Starts the ChatAgent.
  """
  def start_link(opts \\ []) do
    Jido.AgentServer.start(agent: __MODULE__, opts: opts)
  end
end
