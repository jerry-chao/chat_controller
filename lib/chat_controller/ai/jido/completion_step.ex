defmodule ChatController.AI.Jido.CompletionStep do
  @moduledoc """
  Completion step for Jido orchestration.
  """

  def run(state, response) do
    {:ok, state.response_adapter.text(response)}
  end
end
