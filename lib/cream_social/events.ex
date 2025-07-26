defmodule CreamSocial.Events do
  import Ecto.Query, warn: false
  alias CreamSocial.Repo
  alias CreamSocial.Events.{Event, EventRsvp}
  alias CreamSocial.Accounts.User
  alias CreamSocial.Locations.City

  # Event CRUD Operations
  
  def list_events do
    Repo.all(Event)
  end

  def get_event!(id), do: Repo.get!(Event, id)

  def get_event(id), do: Repo.get(Event, id)

  def get_event_by_slug(slug) do
    Repo.get_by(Event, slug: slug)
  end

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  # Event Discovery & Filtering

  def discover_events(opts \\ []) do
    try do
      base_query()
      |> apply_filters(opts)
      |> order_events(opts)
      |> limit_results(opts)
      |> Repo.all()
    rescue
      error ->
        require Logger
        Logger.error("Events discovery query failed: #{inspect(error)}")
        []
    end
  end

  def upcoming_events(city_id \\ nil, limit \\ 20) do
    now = DateTime.utc_now()
    
    base_query()
    |> where([e], e.start_datetime > ^now)
    |> where([e], e.status == "active")
    |> maybe_filter_by_city(city_id)
    |> order_by([e], asc: e.start_datetime)
    |> limit(^limit)
    |> Repo.all()
  end

  def featured_events(city_id \\ nil, limit \\ 5) do
    base_query()
    |> where([e], e.featured == true)
    |> where([e], e.status == "active")
    |> maybe_filter_by_city(city_id)
    |> order_by([e], desc: e.views_count)
    |> limit(^limit)
    |> Repo.all()
  end

  def events_by_category(category, city_id \\ nil, limit \\ 10) do
    base_query()
    |> where([e], e.category == ^category)
    |> where([e], e.status == "active")
    |> maybe_filter_by_city(city_id)
    |> order_by([e], asc: e.start_datetime)
    |> limit(^limit)
    |> Repo.all()
  end

  def events_by_area(area, city_id \\ nil, limit \\ 10) do
    base_query()
    |> where([e], e.area == ^area)
    |> where([e], e.status == "active")
    |> maybe_filter_by_city(city_id)
    |> order_by([e], asc: e.start_datetime)
    |> limit(^limit)
    |> Repo.all()
  end

  def search_events(query, opts \\ []) do
    search_term = "%#{query}%"
    
    base_query()
    |> where([e], 
      ilike(e.title, ^search_term) or 
      ilike(e.description, ^search_term) or
      ilike(e.venue_name, ^search_term) or
      ^query in e.tags
    )
    |> apply_filters(opts)
    |> order_by([e], desc: e.views_count)
    |> limit(20)
    |> Repo.all()
  end

  # RSVP Management

  def create_rsvp(event_id, user_id, attrs \\ %{}) do
    attrs = Map.merge(attrs, %{"event_id" => event_id, "user_id" => user_id})
    
    %EventRsvp{}
    |> EventRsvp.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, rsvp} ->
        update_attendee_count(event_id)
        {:ok, rsvp}
      error -> error
    end
  end

  def update_rsvp(%EventRsvp{} = rsvp, attrs) do
    old_status = rsvp.status
    
    rsvp
    |> EventRsvp.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_rsvp} ->
        if old_status != updated_rsvp.status do
          update_attendee_count(updated_rsvp.event_id)
        end
        {:ok, updated_rsvp}
      error -> error
    end
  end

  def get_user_rsvp(event_id, user_id) do
    Repo.get_by(EventRsvp, event_id: event_id, user_id: user_id)
  end

  def get_event_attendees(event_id, status \\ "going") do
    EventRsvp
    |> where([r], r.event_id == ^event_id and r.status == ^status)
    |> join(:inner, [r], u in User, on: r.user_id == u.id)
    |> select([r, u], %{rsvp: r, user: u})
    |> Repo.all()
  end

  def check_in_attendee(event_id, user_id) do
    case get_user_rsvp(event_id, user_id) do
      nil -> {:error, "RSVP not found"}
      rsvp ->
        update_rsvp(rsvp, %{
          "checked_in" => true,
          "checked_in_at" => DateTime.utc_now()
        })
    end
  end

  # Analytics & Stats

  def increment_view_count(%Event{} = event) do
    event
    |> Event.changeset(%{views_count: event.views_count + 1})
    |> Repo.update()
  end

  def get_event_stats(event_id) do
    going_count = get_rsvp_count(event_id, "going")
    maybe_count = get_rsvp_count(event_id, "maybe")
    
    %{
      going: going_count,
      maybe: maybe_count,
      total_interested: going_count + maybe_count
    }
  end

  def get_organizer_stats(organizer_id) do
    from(e in Event,
      where: e.organizer_id == ^organizer_id,
      select: %{
        total_events: count(e.id),
        total_views: sum(e.views_count),
        total_likes: sum(e.likes_count)
      }
    )
    |> Repo.one()
  end

  # Helper Functions

  defp base_query do
    from(e in Event,
      left_join: o in User, on: e.organizer_id == o.id,
      left_join: c in City, on: e.city_id == c.id,
      preload: [organizer: o, city: c]
    )
  end

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:category, category}, q -> where(q, [e], e.category == ^category)
      {:area, area}, q -> where(q, [e], e.area == ^area)
      {:city_id, city_id}, q -> where(q, [e], e.city_id == ^city_id)
      {:status, status}, q -> where(q, [e], e.status == ^status)
      {:is_free, is_free}, q -> where(q, [e], e.is_free == ^is_free)
      {:upcoming, true}, q -> 
        now = DateTime.utc_now()
        where(q, [e], e.start_datetime > ^now)
      {:date_range, {start_date, end_date}}, q ->
        where(q, [e], e.start_datetime >= ^start_date and e.start_datetime <= ^end_date)
      _, q -> q
    end)
  end

  defp order_events(query, opts) do
    case Keyword.get(opts, :order_by, :start_datetime) do
      :start_datetime -> order_by(query, [e], asc: e.start_datetime)
      :created -> order_by(query, [e], desc: e.inserted_at)
      :popular -> order_by(query, [e], desc: e.views_count)
      :featured -> order_by(query, [e], desc: e.featured, desc: e.views_count)
      _ -> query
    end
  end

  defp limit_results(query, opts) do
    case Keyword.get(opts, :limit) do
      nil -> query
      limit -> limit(query, ^limit)
    end
  end

  defp maybe_filter_by_city(query, nil), do: query
  defp maybe_filter_by_city(query, city_id), do: where(query, [e], e.city_id == ^city_id)

  defp get_rsvp_count(event_id, status) do
    EventRsvp
    |> where([r], r.event_id == ^event_id and r.status == ^status)
    |> Repo.aggregate(:count, :id)
  end

  defp update_attendee_count(event_id) do
    going_count = get_rsvp_count(event_id, "going")
    
    from(e in Event, where: e.id == ^event_id)
    |> Repo.update_all(set: [current_attendees: going_count])
  end
end