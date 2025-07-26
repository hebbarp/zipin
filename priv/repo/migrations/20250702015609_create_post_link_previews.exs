defmodule CreamSocial.Repo.Migrations.CreatePostLinkPreviews do
  use Ecto.Migration

  def change do
    create table(:post_link_previews, primary_key: false) do
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :link_preview_id, references(:link_previews, on_delete: :delete_all), null: false
    end

    create unique_index(:post_link_previews, [:post_id, :link_preview_id])
  end
end
