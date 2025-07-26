defmodule CreamSocial.Repo.Migrations.CreateBookmarks do
  use Ecto.Migration

  def change do
    create table(:bookmarks) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :collection_name, :string
      add :notes, :text

      timestamps()
    end

    create unique_index(:bookmarks, [:user_id, :post_id])
    create index(:bookmarks, [:post_id])
    create index(:bookmarks, [:user_id])
    create index(:bookmarks, [:collection_name])
  end
end
