defmodule ChatController.AI.JidoAI.UserInfoAction do
  @moduledoc """
  User info action using Jido.Action behavior.
  Returns mock user information by user ID.
  """

  use Jido.Action,
    name: "get_user_info",
    description: "Get user information by user ID",
    schema:
      Zoi.object(%{
        user_id: Zoi.integer()
      })

  require Logger

  @impl true
  def run(%{user_id: user_id}, _context) do
    Logger.info("Getting user info for ID #{user_id}")

    user_data = %{
      id: user_id,
      name: "User #{user_id}",
      email: "user#{user_id}@example.com",
      role: Enum.random(["admin", "user", "moderator"]),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    {:ok, user_data}
  end
end
