defmodule CreamSocial.Trending do
  @moduledoc """
  The Trending context for managing trending topics, hashtags, and viral content discovery.
  
  Supports multi-source trending data:
  - RSS feeds from news sources
  - Social media hashtags
  - Google Trends
  - Manual trending topics
  """

  import Ecto.Query, warn: false
  alias CreamSocial.Repo
  alias CreamSocial.Trending.TrendingTopic

  ## Trending Topics

  @doc """
  Returns the list of active trending topics with optional filters.
  """
  def list_trending_topics(options \\ []) do
    location = Keyword.get(options, :location, "bangalore")
    language = Keyword.get(options, :language, "en")
    category = Keyword.get(options, :category, nil)
    source = Keyword.get(options, :source, nil)
    limit = Keyword.get(options, :limit, 10)

    now = DateTime.utc_now()

    query = from t in TrendingTopic,
      where: t.status == "active" and 
             t.location == ^location and
             (is_nil(t.expires_at) or t.expires_at > ^now),
      order_by: [desc: t.score, desc: t.inserted_at],
      limit: ^limit

    query = if language do
      from t in query, where: t.language == ^language
    else
      query
    end

    query = if category do
      from t in query, where: t.category == ^category
    else
      query
    end

    query = if source do
      from t in query, where: t.source == ^source
    else
      query
    end

    Repo.all(query)
  end

  @doc """
  Gets active trending topics by category.
  """
  def get_trending_by_category(category, options \\ []) do
    location = Keyword.get(options, :location, "bangalore")
    limit = Keyword.get(options, :limit, 5)

    TrendingTopic.by_category(category, location, limit)
    |> Repo.all()
  end

  @doc """
  Gets all active trending topics for a location.
  """
  def get_active_topics(location \\ "bangalore", limit \\ 10) do
    TrendingTopic.active_topics(location, limit)
    |> Repo.all()
  end

  @doc """
  Gets a single trending topic by ID.
  """
  def get_trending_topic!(id) do
    Repo.get!(TrendingTopic, id)
  end

  @doc """
  Gets a trending topic by topic and hashtag combination.
  """
  def get_by_topic_hashtag(topic, hashtag, location \\ "bangalore") do
    from(t in TrendingTopic,
      where: t.topic == ^topic and 
             t.hashtag == ^hashtag and 
             t.location == ^location,
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Creates a trending topic.
  """
  def create_trending_topic(attrs \\ %{}) do
    %TrendingTopic{}
    |> TrendingTopic.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a trending topic.
  """
  def update_trending_topic(%TrendingTopic{} = trending_topic, attrs) do
    trending_topic
    |> TrendingTopic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a trending topic.
  """
  def delete_trending_topic(%TrendingTopic{} = trending_topic) do
    Repo.delete(trending_topic)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trending topic changes.
  """
  def change_trending_topic(%TrendingTopic{} = trending_topic, attrs \\ %{}) do
    TrendingTopic.changeset(trending_topic, attrs)
  end

  @doc """
  Increments the score of a trending topic (makes it more trending).
  """
  def boost_trending_topic(id, increment \\ 1) do
    from(t in TrendingTopic, where: t.id == ^id)
    |> Repo.update_all(inc: [score: increment])
  end

  @doc """
  Marks a trending topic as expired.
  """
  def expire_trending_topic(id) do
    from(t in TrendingTopic, where: t.id == ^id)
    |> Repo.update_all(set: [status: "expired", expires_at: DateTime.utc_now()])
  end

  @doc """
  Creates or updates a trending topic from external source (RSS, Social, etc.).
  If topic exists, increases its score. If not, creates new entry.
  """
  def upsert_trending_topic(attrs) do
    topic = Map.get(attrs, "topic") || Map.get(attrs, :topic)
    hashtag = Map.get(attrs, "hashtag") || Map.get(attrs, :hashtag)
    location = Map.get(attrs, "location") || Map.get(attrs, :location) || "bangalore"

    case get_by_topic_hashtag(topic, hashtag, location) do
      nil ->
        # Create new trending topic
        create_trending_topic(attrs)
      
      existing ->
        # Boost existing topic score
        new_score = existing.score + 1
        update_trending_topic(existing, %{score: new_score, updated_at: DateTime.utc_now()})
    end
  end

  @doc """
  Bulk creates trending topics from external APIs (RSS, Google Trends, etc.)
  """
  def bulk_create_trending_topics(topics_list) when is_list(topics_list) do
    results = Enum.map(topics_list, fn topic_attrs ->
      upsert_trending_topic(topic_attrs)
    end)

    {successes, errors} = Enum.split_with(results, fn
      {:ok, _} -> true
      _ -> false
    end)

    %{
      created: length(successes),
      errors: length(errors),
      results: results
    }
  end

  @doc """
  Cleans up expired trending topics.
  """
  def cleanup_expired_topics do
    now = DateTime.utc_now()
    
    expired_count = from(t in TrendingTopic,
      where: not is_nil(t.expires_at) and t.expires_at < ^now
    )
    |> Repo.update_all(set: [status: "expired"])

    {:ok, expired_count}
  end

  @doc """
  Gets trending hashtags for suggestion in posts.
  """
  def get_trending_hashtags(options \\ []) do
    location = Keyword.get(options, :location, "bangalore")
    limit = Keyword.get(options, :limit, 10)
    
    now = DateTime.utc_now()

    from(t in TrendingTopic,
      where: t.status == "active" and 
             t.location == ^location and
             (is_nil(t.expires_at) or t.expires_at > ^now),
      select: %{hashtag: t.hashtag, topic: t.topic, score: t.score, category: t.category},
      order_by: [desc: t.score],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Searches trending topics by keyword.
  """
  def search_trending_topics(query, options \\ []) do
    location = Keyword.get(options, :location, "bangalore")
    limit = Keyword.get(options, :limit, 5)
    
    search_pattern = "%#{query}%"
    now = DateTime.utc_now()

    from(t in TrendingTopic,
      where: t.status == "active" and 
             t.location == ^location and
             (is_nil(t.expires_at) or t.expires_at > ^now) and
             (ilike(t.topic, ^search_pattern) or 
              ilike(t.hashtag, ^search_pattern) or
              ilike(t.description, ^search_pattern)),
      order_by: [desc: t.score, desc: t.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  ## Helper functions for seeding and testing

  @doc """
  Seeds initial trending topics for Bangalore.
  """
  def seed_bangalore_trending do
    initial_topics = [
      %{
        topic: "Namma Metro Purple Line Extension",
        hashtag: "#NammaMetro",
        category: "local",
        source: "manual",
        description: "New metro line connecting Whitefield to City Center",
        score: 25,
        language: "en",
        location: "bangalore"
      },
      %{
        topic: "RCB vs CSK Tonight",
        hashtag: "#RCBvCSK",
        category: "sports",
        source: "manual", 
        description: "Royal Challengers Bangalore vs Chennai Super Kings match tonight",
        score: 30,
        language: "en",
        location: "bangalore"
      },
      %{
        topic: "Bangalore Weather Alert",
        hashtag: "#BangaloreRain",
        category: "local",
        source: "manual",
        description: "Heavy rain expected in Bangalore today",
        score: 20,
        language: "en", 
        location: "bangalore"
      },
      %{
        topic: "Tech Hiring Boom",
        hashtag: "#TechJobs",
        category: "tech",
        source: "manual",
        description: "Major tech companies hiring in Bangalore",
        score: 15,
        language: "en",
        location: "bangalore"
      },
      %{
        topic: "Food Truck Festival",
        hashtag: "#FoodTruck",
        category: "food",
        source: "manual",
        description: "Weekend food truck festival at Cubbon Park",
        score: 18,
        language: "en",
        location: "bangalore"
      }
    ]

    bulk_create_trending_topics(initial_topics)
  end
end