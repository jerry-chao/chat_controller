defmodule ChatController.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field(:title, :string)
    field(:context, :map, default: %{})

    has_many(:messages, ChatController.Chat.Message)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:title, :context])
    |> validate_required([])
  end
end
