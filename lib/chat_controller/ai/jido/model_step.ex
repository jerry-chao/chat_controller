defmodule ChatController.AI.Jido.ModelStep do
  @moduledoc """
  Model execution step for Jido orchestration.
  """

  def run(state) do
    state.llm_adapter.generate_text_with_tools(state.model, state.messages, state.tools)
  end
end
