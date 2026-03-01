defmodule ChatController.Repo do
  use Ecto.Repo,
    otp_app: :chat_controller,
    adapter: Ecto.Adapters.Postgres
end
