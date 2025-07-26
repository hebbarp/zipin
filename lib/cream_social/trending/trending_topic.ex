defmodule CreamSocial.Trending.TrendingTopic do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "trending_topics" do
    field :topic, :string
    field :hashtag, :string
    field :category, :string
    field :source, :string
    field :source_url, :string
    field :description, :string
    field :score, :integer, default: 1
    field :language, :string, default: "en"
    field :location, :string, default: "bangalore"
    field :expires_at, :utc_datetime
    field :status, :string, default: "active"
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trending_topic, attrs) do
    trending_topic
    |> cast(attrs, [
      :topic, :hashtag, :category, :source, :source_url, :description,
      :score, :language, :location, :expires_at, :status, :metadata
    ])
    |> validate_required([:topic, :hashtag, :category, :source])
    |> validate_inclusion(:status, ["active", "expired", "hidden"])
    |> validate_inclusion(:language, ["en", "hi", "kn"])
    |> validate_inclusion(:category, ["local", "national", "global", "bangalore", "tech", "food", "sports", "culture", "business"])
    |> validate_inclusion(:source, ["rss", "social", "google_trends", "manual", "news"])
    |> validate_number(:score, greater_than: 0)
    |> unique_constraint([:topic, :hashtag, :location])
  end

  def categories do
    %{
      "local" => "🏙️ Local Bangalore",
      "national" => "🇮🇳 National India", 
      "global" => "🌍 Global",
      "bangalore" => "🌆 Bangalore Specific",
      "tech" => "💻 Technology",
      "food" => "🍽️ Food & Dining",
      "sports" => "⚽ Sports",
      "culture" => "🎭 Arts & Culture",
      "business" => "💼 Business"
    }
  end

  def sources do
    %{
      "rss" => "📰 RSS Feeds",
      "social" => "📱 Social Media",
      "google_trends" => "📈 Google Trends",
      "manual" => "✋ Manual Entry",
      "news" => "📺 News APIs"
    }
  end

  def active_topics(location \\ "bangalore", limit \\ 10) do
    now = DateTime.utc_now()
    
    from t in __MODULE__,
      where: t.status == "active" and
             t.location == ^location and
             (is_nil(t.expires_at) or t.expires_at > ^now),
      order_by: [desc: t.score, desc: t.inserted_at],
      limit: ^limit
  end

  def by_category(category, location \\ "bangalore", limit \\ 5) do
    now = DateTime.utc_now()
    
    from t in __MODULE__,
      where: t.status == "active" and
             t.location == ^location and
             t.category == ^category and
             (is_nil(t.expires_at) or t.expires_at > ^now),
      order_by: [desc: t.score, desc: t.inserted_at],
      limit: ^limit
  end
end