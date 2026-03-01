defmodule ChatController.AI.ChatAgent do
  @moduledoc """
  Chat agent using Jido.AI for tool-calling capabilities.
  This module now delegates to ChatController.AI.JidoAI.Agent.
  """

  # Delegate to JidoAI.Agent for backward compatibility
  defdelegate start_link(opts \\ []), to: ChatController.AI.JidoAI.Agent

  defdelegate ask_sync(agent, message, opts \\ []), to: ChatController.AI.JidoAI.Agent
end
