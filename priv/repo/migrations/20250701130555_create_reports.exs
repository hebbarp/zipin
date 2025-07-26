defmodule CreamSocial.Repo.Migrations.CreateReports do
  use Ecto.Migration

  def change do
    create table(:reports) do
      add :reason, :string, null: false
      add :description, :text
      add :status, :string, default: "pending"
      add :reporter_id, references(:users, on_delete: :delete_all), null: false
      add :reported_user_id, references(:users, on_delete: :delete_all)
      add :reported_post_id, references(:posts, on_delete: :delete_all)
      add :moderator_id, references(:users, on_delete: :nilify_all)
      add :resolved_at, :naive_datetime
      add :resolution_notes, :text

      timestamps()
    end

    create index(:reports, [:status])
    create index(:reports, [:reporter_id])
    create index(:reports, [:reported_user_id])
    create index(:reports, [:reported_post_id])
    create index(:reports, [:moderator_id])
  end
end
