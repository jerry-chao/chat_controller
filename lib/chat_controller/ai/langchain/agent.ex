defmodule ChatController.AI.LangChain.Agent do
  @moduledoc """
  Chat agent using LangChain for tool-calling capabilities.
  Replaces the Jido.AI implementation with LangChain.
  """

  use GenServer
  require Logger

  alias ChatController.AI.LangChain.Tools
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message
  alias LangChain.Function

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

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def ask_sync(agent, message, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 45_000)
    GenServer.call(agent, {:ask, message}, timeout)
  end

  @impl true
  def init(_opts) do
    model = build_model()
    tools = build_tools()

    {:ok, %{model: model, tools: tools, conversation: []}}
  end

  @impl true
  def handle_call({:ask, user_message}, _from, state) do
    Logger.info("Received message: #{user_message}")

    # 构建初始的 chain，添加系统消息和对话历史
    chain =
      LLMChain.new!(%{
        llm: state.model,
        verbose: true
      })
      |> LLMChain.add_message(Message.new_system!(@system_prompt))
      |> then(fn chain ->
        Enum.reduce(state.conversation, chain, fn msg, acc ->
          LLMChain.add_message(acc, msg)
        end)
      end)
      |> LLMChain.add_message(Message.new_user!(user_message))
      |> LLMChain.add_tools(state.tools)

    case LLMChain.run(chain, mode: :while_needs_response) do
      {:ok, updated_chain} ->
        final_message = List.last(updated_chain.messages)
        response_text = extract_content(final_message)

        new_conversation =
          state.conversation ++
            [Message.new_user!(user_message), Message.new_assistant!(response_text)]

        {:reply, {:ok, response_text}, %{state | conversation: new_conversation}}

      {:error, reason} ->
        Logger.error("LangChain error: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  defp build_model do
    ChatOpenAI.new!(%{
      model: System.get_env("LLM_MODEL", "glm-5"),
      api_key: Application.get_env(:langchain, :openai_key),
      endpoint: Application.get_env(:langchain, :openai_endpoint),
      temperature: 0.7,
      stream: false
    })
  end

  defp build_tools do
    [
      Function.new!(%{
        name: "get_weather",
        description: "Get weather information for a city",
        parameters_schema: %{
          type: "object",
          properties: %{
            city: %{type: "string", description: "The city name"}
          },
          required: ["city"]
        },
        function: fn args, _context ->
          Tools.Weather.execute(args, nil)
        end
      }),
      Function.new!(%{
        name: "get_user_info",
        description: "Get user information by user ID",
        parameters_schema: %{
          type: "object",
          properties: %{
            user_id: %{type: "integer", description: "The user ID"}
          },
          required: ["user_id"]
        },
        function: fn args, _context ->
          Tools.UserInfo.execute(args, nil)
        end
      }),
      Function.new!(%{
        name: "fetch_remote_data",
        description: "Fetch data from a remote HTTP endpoint",
        parameters_schema: %{
          type: "object",
          properties: %{
            url: %{type: "string", description: "The URL to fetch"},
            method: %{type: "string", description: "HTTP method", default: "GET"}
          },
          required: ["url"]
        },
        function: fn args, _context ->
          Tools.HttpFetch.execute(args, nil)
        end
      })
    ]
  end

  defp extract_content(%{content: content}) when is_binary(content), do: content

  defp extract_content(%{content: parts}) when is_list(parts) do
    parts
    |> Enum.map(fn
      %{type: "text", text: text} -> text
      %{"type" => "text", "text" => text} -> text
      text when is_binary(text) -> text
      _ -> ""
    end)
    |> Enum.join("")
  end

  defp extract_content(%{role: "assistant", content: content}), do: content
  defp extract_content(_), do: ""
end
