defmodule CreamSocial.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :content, :text, null: false
      add :media_paths, {:array, :string}, default: []
      add :metadata, :map, default: %{}
      add :visibility, :string, default: "public"
      add :scheduled_at, :naive_datetime
      add :published_at, :naive_datetime
      add :edited_at, :naive_datetime
      add :deleted_at, :naive_datetime
      add :likes_count, :integer, default: 0
      add :comments_count, :integer, default: 0
      add :shares_count, :integer, default: 0
      add :views_count, :integer, default: 0
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :parent_id, references(:posts, on_delete: :delete_all)
      add :category_id, references(:categories, on_delete: :nilify_all)

      timestamps()
    end

    create index(:posts, [:user_id])
    create index(:posts, [:parent_id])
    create index(:posts, [:category_id])
    create index(:posts, [:visibility])
    create index(:posts, [:published_at])
    create index(:posts, [:deleted_at])
  end
end
