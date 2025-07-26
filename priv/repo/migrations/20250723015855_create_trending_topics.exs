defmodule CreamSocial.Repo.Migrations.CreateTrendingTopics do
  use Ecto.Migration

  def change do
    create table(:trending_topics) do
      add :topic, :string, null: false
      add :hashtag, :string, null: false
      add :category, :string, null: false  # "local", "national", "global", "bangalore", "tech", etc.
      add :source, :string, null: false   # "rss", "social", "google_trends", "manual"
      add :source_url, :string            # URL of the source
      add :description, :text              # Brief description of the trend
      add :score, :integer, default: 1    # Trending score (higher = more trending)
      add :language, :string, default: "en"  # "en", "hi", "kn" for Kannada
      add :location, :string, default: "bangalore"  # Location relevance
      add :expires_at, :utc_datetime      # When this trend should stop being shown
      add :status, :string, default: "active"  # "active", "expired", "hidden"
      add :metadata, :map                 # JSON field for additional data
      
      timestamps(type: :utc_datetime)
    end

    create index(:trending_topics, [:status, :location, :category])
    create index(:trending_topics, [:score, :expires_at])
    create index(:trending_topics, [:hashtag])
    create unique_index(:trending_topics, [:topic, :hashtag, :location])
  end
end