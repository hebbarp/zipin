defmodule CreamSocial.Repo.Migrations.CreateChannelPosts do
  use Ecto.Migration

  def change do
    create table(:channel_posts) do
      add :channel_id, references(:channels, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :position, :integer, default: 0

      timestamps()
    end

    create unique_index(:channel_posts, [:channel_id, :post_id])
    create index(:channel_posts, [:post_id])
    create index(:channel_posts, [:channel_id, :position])
  end
end
