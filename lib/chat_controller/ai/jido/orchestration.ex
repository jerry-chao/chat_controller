defmodule ChatController.AI.Jido.Orchestration do
  @moduledoc """
  Jido-style orchestration flow for model and tool execution.
  """

  alias ChatController.AI.Jido.{CompletionStep, ModelStep, ToolStep}

  def run(opts) do
    state = initial_state(opts)
    do_run(state)
  end

  defp do_run(%{iteration: iteration, max_iterations: max_iterations})
       when iteration >= max_iterations do
    {:error, :max_iterations_reached}
  end

  defp do_run(state) do
    case ModelStep.run(state) do
      {:ok, response} ->
        case state.response_adapter.tool_calls(response) do
          [] ->
            CompletionStep.run(state, response)

          tool_calls ->
            {:ok, new_messages} = ToolStep.run(state, response, tool_calls)

            do_run(%{
              state
              | iteration: state.iteration + 1,
                messages: state.messages ++ new_messages
            })
        end

      {:error, reason} ->
        {:error, normalize_error(reason)}
    end
  end

  defp initial_state(opts) do
    messages = [
      ReqLLM.Context.system(Keyword.fetch!(opts, :system_prompt)),
      ReqLLM.Context.user(Keyword.fetch!(opts, :user_message))
    ]

    %{
      model: Keyword.fetch!(opts, :model),
      tools: Keyword.fetch!(opts, :tools),
      tool_context: Keyword.get(opts, :tool_context, %{}),
      llm_adapter: Keyword.get(opts, :llm_adapter, ChatController.AI.LLM),
      response_adapter: Keyword.get(opts, :response_adapter, ChatController.AI.LLMResponse),
      max_iterations: Keyword.fetch!(opts, :max_iterations),
      iteration: 0,
      messages: messages
    }
  end

  defp normalize_error(%{reason: reason}), do: reason
  defp normalize_error(reason), do: reason
end
