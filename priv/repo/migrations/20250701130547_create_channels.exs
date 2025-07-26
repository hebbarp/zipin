defmodule CreamSocial.Repo.Migrations.CreateChannels do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add :name, :string, null: false
      add :description, :text
      add :slug, :string, null: false
      add :banner_image, :string
      add :privacy, :string, default: "public"
      add :posts_count, :integer, default: 0
      add :followers_count, :integer, default: 0
      add :active, :boolean, default: true
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:channels, [:slug])
    create index(:channels, [:user_id])
    create index(:channels, [:privacy])
    create index(:channels, [:active])
  end
end
