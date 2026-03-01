defmodule ChatController.AI.ChatAgent do
  @moduledoc """
  Chat agent using ReqLLM for tool-calling capabilities.
  """

  use GenServer

  alias ChatController.AI.{LLM, Tools}
  alias ChatController.AI.Jido.Orchestration

  @default_model "gpt-3.5-turbo"
  @max_iterations 8

  @system_prompt """
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

  # Client API

  @doc """
  Starts the ChatAgent.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Sends a message to the agent and waits for a response.

  ## Options
  - `:timeout` - Request timeout in milliseconds (default: 30_000)
  - `:tool_context` - Context map passed to tools (e.g., %{current_user: user})
  """
  def ask_sync(agent, message, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 30_000)
    tool_context = Keyword.get(opts, :tool_context, %{})

    GenServer.call(agent, {:ask, message, tool_context}, timeout)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    LLM.configure()

    state = %{
      model:
        Keyword.get(
          opts,
          :model,
          Application.get_env(:chat_controller, :llm_model, @default_model)
        ),
      system_prompt: Keyword.get(opts, :system_prompt, @system_prompt),
      tools: Keyword.get(opts, :tools, Tools.all()),
      llm_adapter: Application.get_env(:chat_controller, :llm_adapter, LLM),
      response_adapter:
        Application.get_env(
          :chat_controller,
          :llm_response_adapter,
          ChatController.AI.LLMResponse
        ),
      max_iterations:
        Keyword.get(
          opts,
          :max_iterations,
          Application.get_env(:chat_controller, :max_iterations, @max_iterations)
        )
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:ask, message, tool_context}, _from, state) do
    result =
      Orchestration.run(
        model: state.model,
        system_prompt: state.system_prompt,
        user_message: message,
        tools: state.tools,
        tool_context: tool_context,
        max_iterations: state.max_iterations,
        llm_adapter: state.llm_adapter,
        response_adapter: state.response_adapter
      )

    {:reply, result, state}
  end
end
