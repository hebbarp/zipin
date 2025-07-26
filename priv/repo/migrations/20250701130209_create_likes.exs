defmodule CreamSocial.Repo.Migrations.CreateLikes do
  use Ecto.Migration

  def change do
    create table(:likes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :reaction_type, :string, default: "like"

      timestamps()
    end

    create unique_index(:likes, [:user_id, :post_id])
    create index(:likes, [:post_id])
    create index(:likes, [:user_id])
  end
end
