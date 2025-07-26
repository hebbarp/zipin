defmodule CreamSocial.Repo.Migrations.CreateLinkPreviews do
  use Ecto.Migration

  def change do
    create table(:link_previews) do
      add :url, :string, null: false
      add :title, :string
      add :description, :text
      add :image_url, :string
      add :site_name, :string
      add :cached_at, :naive_datetime

      timestamps()
    end

    create unique_index(:link_previews, [:url])
  end
end
