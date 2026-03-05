defmodule ChatController.AI.ChatAgent do
  @moduledoc """
  Chat agent using LangChain for tool-calling capabilities.
  This module delegates to ChatController.AI.LangChain.Agent.
  """

  defdelegate start_link(opts \\ []), to: ChatController.AI.LangChain.Agent

  defdelegate ask_sync(agent, message, opts \\ []), to: ChatController.AI.LangChain.Agent
end
