defmodule CreamSocial.Repo.Migrations.CreateAnalytics do
  use Ecto.Migration

  def change do
    create table(:analytics) do
      add :event_type, :string, null: false
      add :entity_type, :string, null: false
      add :entity_id, :integer, null: false
      add :user_id, references(:users, on_delete: :delete_all)
      add :ip_address, :string
      add :user_agent, :string
      add :metadata, :map, default: %{}
      add :occurred_at, :naive_datetime, null: false

      timestamps()
    end

    create index(:analytics, [:event_type])
    create index(:analytics, [:entity_type, :entity_id])
    create index(:analytics, [:user_id])
    create index(:analytics, [:occurred_at])
  end
end
