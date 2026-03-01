defmodule ChatController.AI.LLMResponse do
  @moduledoc """
  Response adapter for extracting data from LLM responses.
  """

  def text(response), do: Map.get(response, :text, "")

  def tool_calls(response), do: Map.get(response, :tool_calls, [])

  def assistant_message(response) do
    ReqLLM.Context.assistant(text(response), tool_calls: tool_calls(response))
  end
end
