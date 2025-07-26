defmodule CreamSocial.Places do
  @moduledoc """
  The Places context for managing places, reviews, and discovery in Bangalore.
  """

  import Ecto.Query, warn: false
  alias CreamSocial.Repo
  alias CreamSocial.Places.{Place, PlaceReview}

  ## Places

  @doc """
  Returns the list of places with optional filters.
  """
  def list_places(filters \\ %{}) do
    Place
    |> apply_place_filters(filters)
    |> preload_place_associations()
    |> Repo.all()
  end

  @doc """
  Gets a single place by id.
  """
  def get_place!(id) do
    Place
    |> preload_place_associations()
    |> Repo.get!(id)
  end

  @doc """
  Gets a single place by id (returns nil if not found).
  """
  def get_place(id) do
    Place
    |> preload_place_associations()
    |> Repo.get(id)
  end

  @doc """
  Gets a place by google_place_id.
  """
  def get_place_by_google_id(google_place_id) do
    Place
    |> where([p], p.google_place_id == ^google_place_id)
    |> preload_place_associations()
    |> Repo.one()
  end

  @doc """
  Creates a place.
  """
  def create_place(attrs \\ %{}) do
    %Place{}
    |> Place.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a place.
  """
  def update_place(%Place{} = place, attrs) do
    place
    |> Place.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a place.
  """
  def delete_place(%Place{} = place) do
    Repo.delete(place)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking place changes.
  """
  def change_place(%Place{} = place, attrs \\ %{}) do
    Place.changeset(place, attrs)
  end

  @doc """
  Discovers places by area and category with intelligent filtering.
  """
  def discover_places(area, category \\ nil, options \\ %{}) do
    query = from p in Place,
      where: p.area == ^area and p.status == "active",
      order_by: [desc: p.featured, desc: p.community_rating, desc: p.google_rating]

    query = if category do
      from p in query, where: p.category == ^category
    else
      query
    end

    # Apply additional filters
    query = case options do
      %{wifi_required: true} -> from p in query, where: p.wifi_available == true
      %{parking_required: true} -> from p in query, where: p.parking_available == true
      %{price_range: price} -> from p in query, where: p.price_range == ^price
      _ -> query
    end

    # Limit results for performance
    limit = Map.get(options, :limit, 20)
    
    query
    |> limit(^limit)
    |> preload_place_associations()
    |> Repo.all()
  end

  @doc """
  Search places by name, description, or area.
  """
  def search_places(search_term, options \\ %{}) do
    search_pattern = "%#{search_term}%"
    
    query = from p in Place,
      where: p.status == "active" and (
        ilike(p.name, ^search_pattern) or
        ilike(p.description, ^search_pattern) or
        ilike(p.area, ^search_pattern) or
        ilike(p.address, ^search_pattern)
      ),
      order_by: [desc: p.featured, desc: p.community_rating]

    limit = Map.get(options, :limit, 10)
    
    query
    |> limit(^limit)
    |> preload_place_associations()
    |> Repo.all()
  end

  @doc """
  Get featured places for the homepage.
  """
  def get_featured_places(limit \\ 10) do
    from(p in Place,
      where: p.featured == true and p.status == "active",
      order_by: [desc: p.community_rating, desc: p.google_rating],
      limit: ^limit
    )
    |> preload_place_associations()
    |> Repo.all()
  end

  @doc """
  Get trending places based on recent reviews and ratings.
  """
  def get_trending_places(limit \\ 10) do
    # Places with recent reviews and high ratings
    thirty_days_ago = DateTime.utc_now() |> DateTime.add(-30, :day)
    
    from(p in Place,
      join: r in assoc(p, :reviews),
      where: p.status == "active" and r.inserted_at > ^thirty_days_ago,
      group_by: p.id,
      having: count(r.id) >= 2,
      order_by: [desc: avg(r.rating), desc: count(r.id)],
      limit: ^limit
    )
    |> preload_place_associations()
    |> Repo.all()
  end

  ## Place Reviews

  @doc """
  Returns the list of reviews for a place.
  """
  def list_place_reviews(place_id, options \\ %{}) do
    query = from r in PlaceReview,
      where: r.place_id == ^place_id and r.status == "active",
      order_by: [desc: r.helpful_count, desc: r.inserted_at],
      preload: [:user]

    limit = Map.get(options, :limit, 20)
    
    query
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Gets a single review.
  """
  def get_review!(id) do
    PlaceReview
    |> preload([:place, :user])
    |> Repo.get!(id)
  end

  @doc """
  Creates a review for a place.
  """
  def create_review(attrs \\ %{}) do
    changeset = %PlaceReview{}
    |> PlaceReview.changeset(attrs)
    
    case Repo.insert(changeset) do
      {:ok, review} ->
        # Update place community rating
        update_place_community_rating(review.place_id)
        {:ok, review}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a review.
  """
  def update_review(%PlaceReview{} = review, attrs) do
    case review
    |> PlaceReview.changeset(attrs)
    |> Repo.update() do
      {:ok, updated_review} ->
        # Update place community rating
        update_place_community_rating(updated_review.place_id)
        {:ok, updated_review}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes a review.
  """
  def delete_review(%PlaceReview{} = review) do
    case Repo.delete(review) do
      {:ok, deleted_review} ->
        # Update place community rating
        update_place_community_rating(deleted_review.place_id)
        {:ok, deleted_review}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking review changes.
  """
  def change_review(%PlaceReview{} = review, attrs \\ %{}) do
    PlaceReview.changeset(review, attrs)
  end

  @doc """
  Marks a review as helpful.
  """
  def mark_review_helpful(review_id) do
    from(r in PlaceReview, where: r.id == ^review_id)
    |> Repo.update_all(inc: [helpful_count: 1])
  end

  @doc """
  Marks a review as unhelpful.
  """
  def mark_review_unhelpful(review_id) do
    from(r in PlaceReview, where: r.id == ^review_id)
    |> Repo.update_all(inc: [unhelpful_count: 1])
  end

  ## Helper Functions

  defp apply_place_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:area, area}, query when is_binary(area) ->
        from p in query, where: p.area == ^area
      
      {:category, category}, query when is_binary(category) ->
        from p in query, where: p.category == ^category
      
      {:subcategory, subcategory}, query when is_binary(subcategory) ->
        from p in query, where: p.subcategory == ^subcategory
      
      {:wifi_available, true}, query ->
        from p in query, where: p.wifi_available == true
      
      {:parking_available, true}, query ->
        from p in query, where: p.parking_available == true
      
      {:price_range, price_range}, query when is_binary(price_range) ->
        from p in query, where: p.price_range == ^price_range
      
      {:min_rating, rating}, query when is_number(rating) ->
        from p in query, where: p.community_rating >= ^rating or (is_nil(p.community_rating) and p.google_rating >= ^rating)
      
      {:featured, true}, query ->
        from p in query, where: p.featured == true
      
      _, query -> query
    end)
  end

  defp preload_place_associations(query) do
    preload(query, [:reviews, :created_by])
  end

  defp update_place_community_rating(place_id) do
    # Calculate average rating from all reviews
    case from(r in PlaceReview,
      where: r.place_id == ^place_id and r.status == "active",
      select: {avg(r.rating), count(r.id)}
    ) |> Repo.one() do
      {nil, 0} ->
        # No reviews, set to nil
        from(p in Place, where: p.id == ^place_id)
        |> Repo.update_all(set: [community_rating: nil, community_total_ratings: 0])
      
      {avg_rating, count} ->
        # Update with calculated average
        rounded_rating = Decimal.round(avg_rating, 1)
        from(p in Place, where: p.id == ^place_id)
        |> Repo.update_all(set: [community_rating: rounded_rating, community_total_ratings: count])
    end
  end
end