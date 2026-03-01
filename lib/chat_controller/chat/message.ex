defmodule ChatController.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field(:role, :string)
    field(:content, :string)
    field(:metadata, :map, default: %{})

    belongs_to(:conversation, ChatController.Chat.Conversation)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:role, :content, :metadata, :conversation_id])
    |> validate_required([:role, :content])
    |> validate_inclusion(:role, ["user", "assistant", "system"])
  end
end
