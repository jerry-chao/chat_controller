defmodule ChatController.AI.Jido.ToolStep do
  @moduledoc """
  Tool execution step for Jido orchestration.
  """

  def run(state, response, tool_calls) do
    assistant_message = state.response_adapter.assistant_message(response)

    tool_messages =
      Enum.map(tool_calls, fn tool_call ->
        execute_tool(tool_call, state.tools, state.tool_context)
      end)

    {:ok, [assistant_message | tool_messages]}
  end

  defp execute_tool(tool_call, tools, tool_context) do
    tool_name = tool_call.function.name
    tool = Enum.find(tools, fn t -> t.name == tool_name end)

    result =
      if tool do
        with {:ok, args} <- Jason.decode(tool_call.function.arguments),
             {:ok, encoded_result} <- run_tool(tool, args, tool_context) do
          encoded_result
        else
          {:error, reason} -> Jason.encode!(%{error: inspect(reason)})
        end
      else
        Jason.encode!(%{error: "Tool not found: #{tool_name}"})
      end

    ReqLLM.Context.tool_result(tool_call.id, tool_name, result)
  end

  defp run_tool(tool, args, tool_context) do
    Process.put(:tool_context, tool_context)

    try do
      normalized_args = normalize_tool_args(args)

      case ReqLLM.Tool.execute(tool, normalized_args) do
        {:ok, result} -> {:ok, Jason.encode!(result)}
        {:error, reason} -> {:error, reason}
      end
    after
      Process.delete(:tool_context)
    end
  end

  defp normalize_tool_args(args) when is_map(args) do
    Map.new(args, fn {k, v} ->
      case maybe_existing_atom(k) do
        {:ok, atom_key} -> {atom_key, v}
        :error -> {k, v}
      end
    end)
  end

  defp maybe_existing_atom(k) when is_atom(k), do: {:ok, k}

  defp maybe_existing_atom(k) when is_binary(k) do
    try do
      {:ok, String.to_existing_atom(k)}
    rescue
      ArgumentError -> :error
    end
  end

  defp maybe_existing_atom(_), do: :error
end
