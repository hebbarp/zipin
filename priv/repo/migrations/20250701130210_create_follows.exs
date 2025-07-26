defmodule CreamSocial.Repo.Migrations.CreateFollows do
  use Ecto.Migration

  def change do
    create table(:follows) do
      add :follower_id, references(:users, on_delete: :delete_all), null: false
      add :followed_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, default: "active"
      add :notifications_enabled, :boolean, default: true

      timestamps()
    end

    create unique_index(:follows, [:follower_id, :followed_id])
    create index(:follows, [:followed_id])
    create index(:follows, [:follower_id])
    create index(:follows, [:status])
  end
end
