defmodule ChatController.Repo.Migrations.CreateConversations do
  use Ecto.Migration

    create table(:conversations) do
      add :title, :string
      add :context, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create table(:messages) do
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :role, :string, null: false
      add :content, :text, null: false
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:inserted_at])
  end
end
