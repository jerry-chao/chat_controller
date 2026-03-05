defmodule ChatController.AI.LangChain.Tools.UserInfo do
  @moduledoc """
  User info tool using LangChain.Function.
  Returns mock user information by user ID.
  """

  require Logger

  @doc """
  Returns the user info tool function definition for LangChain.
  """
  def function do
    %{
      name: "get_user_info",
      description: "Get user information by user ID",
      parameters_schema: %{
        type: "object",
        properties: %{
          user_id: %{
            type: "integer",
            description: "The user ID to look up"
          }
        },
        required: ["user_id"]
      },
      function: &execute/2
    }
  end

  @doc """
  Executes the user info lookup.
  """
  def execute(args, _context) do
    user_id = Map.get(args, "user_id") || Map.get(args, :user_id)
    Logger.info("Getting user info for ID #{user_id}")

    user_data = %{
      id: user_id,
      name: "User #{user_id}",
      email: "user#{user_id}@example.com",
      role: Enum.random(["admin", "user", "moderator"]),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Jason.encode!(user_data)
  end
end
