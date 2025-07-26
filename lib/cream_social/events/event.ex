defmodule CreamSocial.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Accounts.User
  alias CreamSocial.Locations.City
  alias CreamSocial.Places.Place
  alias CreamSocial.Events.EventRsvp

  schema "events" do
    # Basic Info
    field :title, :string
    field :description, :string
    field :category, :string
    field :subcategory, :string
    field :slug, :string
    
    # Date & Time
    field :start_datetime, :utc_datetime
    field :end_datetime, :utc_datetime
    field :timezone, :string
    field :recurring, :boolean
    field :recurring_pattern, :string
    
    # Location
    field :venue_name, :string
    field :venue_address, :string
    field :area, :string
    field :latitude, :decimal
    field :longitude, :decimal
    field :is_online, :boolean
    field :online_link, :string
    
    # Capacity & Pricing
    field :max_attendees, :integer
    field :current_attendees, :integer
    field :is_free, :boolean
    field :ticket_price, :decimal
    field :currency, :string
    
    # Event Management
    field :status, :string
    field :visibility, :string
    field :requires_approval, :boolean
    field :tags, {:array, :string}
    
    # Social Features
    field :featured, :boolean
    field :likes_count, :integer
    field :shares_count, :integer
    field :views_count, :integer
    
    # Images
    field :image_url, :string
    field :images, :map, default: %{}
    
    # Associations
    belongs_to :organizer, User
    belongs_to :city, City
    belongs_to :place, Place
    has_many :rsvps, EventRsvp

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :title, :description, :category, :subcategory, :slug,
      :start_datetime, :end_datetime, :timezone, :recurring, :recurring_pattern,
      :venue_name, :venue_address, :area, :latitude, :longitude, :is_online, :online_link,
      :max_attendees, :current_attendees, :is_free, :ticket_price, :currency,
      :status, :visibility, :requires_approval, :tags,
      :featured, :likes_count, :shares_count, :views_count,
      :organizer_id, :city_id, :place_id, :image_url, :images
    ])
    |> validate_required([:title, :category, :start_datetime, :organizer_id])
    |> validate_length(:title, min: 5, max: 100)
    |> validate_length(:description, max: 2000)
    |> validate_inclusion(:category, ["tech", "social", "sports", "culture", "professional", "food", "entertainment", "health"])
    |> validate_inclusion(:status, ["active", "cancelled", "completed"])
    |> validate_inclusion(:visibility, ["public", "private", "invite_only"])
    |> validate_number(:max_attendees, greater_than: 0)
    |> validate_number(:ticket_price, greater_than_or_equal_to: 0)
    |> validate_datetime_order()
    |> generate_slug_if_needed()
    |> unique_constraint(:slug)
  end

  defp validate_datetime_order(changeset) do
    start_datetime = get_field(changeset, :start_datetime)
    end_datetime = get_field(changeset, :end_datetime)
    
    if start_datetime && end_datetime && DateTime.compare(end_datetime, start_datetime) != :gt do
      add_error(changeset, :end_datetime, "must be after start datetime")
    else
      changeset
    end
  end

  defp generate_slug_if_needed(changeset) do
    case get_field(changeset, :slug) do
      nil ->
        title = get_field(changeset, :title)
        if title do
          slug = title
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9\s-]/, "")
          |> String.replace(~r/\s+/, "-")
          |> String.slice(0, 50)
          
          put_change(changeset, :slug, slug)
        else
          changeset
        end
      _ -> changeset
    end
  end

  # Event categories with icons and descriptions
  def categories do
    %{
      "tech" => %{
        name: "Tech & Startups",
        icon: "💻",
        subcategories: [
          "meetup", "conference", "workshop", "hackathon", 
          "networking", "product_launch", "demo_day"
        ]
      },
      "social" => %{
        name: "Social & Networking", 
        icon: "🤝",
        subcategories: [
          "meetup", "party", "mixer", "community", 
          "language_exchange", "book_club", "game_night"
        ]
      },
      "sports" => %{
        name: "Sports & Fitness",
        icon: "⚽",
        subcategories: [
          "cricket", "football", "badminton", "cycling", 
          "running", "yoga", "fitness", "tournament"
        ]
      },
      "culture" => %{
        name: "Arts & Culture",
        icon: "🎭",
        subcategories: [
          "music", "dance", "theatre", "art_exhibition",
          "festival", "poetry", "literature", "photography"
        ]
      },
      "professional" => %{
        name: "Professional & Career",
        icon: "💼",
        subcategories: [
          "networking", "conference", "seminar", "workshop",
          "job_fair", "mentorship", "skill_building"
        ]
      },
      "food" => %{
        name: "Food & Dining",
        icon: "🍽️",
        subcategories: [
          "food_festival", "cooking_class", "wine_tasting",
          "restaurant_event", "food_tour", "potluck"
        ]
      },
      "entertainment" => %{
        name: "Entertainment",
        icon: "🎪",
        subcategories: [
          "comedy", "music_concert", "movie_screening",
          "quiz", "karaoke", "stand_up", "open_mic"
        ]
      },
      "health" => %{
        name: "Health & Wellness",
        icon: "🧘",
        subcategories: [
          "yoga", "meditation", "fitness", "mental_health",
          "nutrition", "wellness", "healthcare"
        ]
      }
    }
  end

  def category_options do
    categories()
    |> Enum.map(fn {key, value} -> {value.name, key} end)
    |> Enum.sort()
  end

  def subcategory_options(category) do
    case categories()[category] do
      nil -> []
      category_info ->
        category_info.subcategories
        |> Enum.map(fn sub -> 
          display_name = sub |> String.replace("_", " ") |> String.capitalize()
          {display_name, sub}
        end)
        |> Enum.sort()
    end
  end

  def get_category_icon(category) do
    case categories()[category] do
      %{icon: icon} -> icon
      _ -> "📅"
    end
  end

  def status_options do
    [
      {"Active", "active"},
      {"Cancelled", "cancelled"}, 
      {"Completed", "completed"}
    ]
  end

  def visibility_options do
    [
      {"Public", "public"},
      {"Private", "private"},
      {"Invite Only", "invite_only"}
    ]
  end

  def is_upcoming?(%__MODULE__{start_datetime: start_datetime}) do
    DateTime.compare(start_datetime, DateTime.utc_now()) == :gt
  end

  def is_past?(%__MODULE__{end_datetime: nil, start_datetime: start_datetime}) do
    # If no end time, assume 2 hour duration
    end_time = DateTime.add(start_datetime, 2, :hour)
    DateTime.compare(end_time, DateTime.utc_now()) == :lt
  end

  def is_past?(%__MODULE__{end_datetime: end_datetime}) do
    DateTime.compare(end_datetime, DateTime.utc_now()) == :lt
  end

  def is_happening_now?(%__MODULE__{} = event) do
    now = DateTime.utc_now()
    start_passed = DateTime.compare(event.start_datetime, now) != :gt
    
    end_time = event.end_datetime || DateTime.add(event.start_datetime, 2, :hour)
    end_not_passed = DateTime.compare(end_time, now) == :gt
    
    start_passed && end_not_passed
  end

  def format_datetime(%DateTime{} = datetime, _timezone \\ "Asia/Kolkata") do
    # For now, assume UTC times and add IST offset manually (+5:30)
    ist_datetime = DateTime.add(datetime, 5 * 3600 + 30 * 60, :second)
    Calendar.strftime(ist_datetime, "%d %b %Y, %I:%M %p IST")
  end

  def format_date(%DateTime{} = datetime, _timezone \\ "Asia/Kolkata") do
    # For now, assume UTC times and add IST offset manually (+5:30)
    ist_datetime = DateTime.add(datetime, 5 * 3600 + 30 * 60, :second)
    Calendar.strftime(ist_datetime, "%d %b %Y")
  end

  def format_time(%DateTime{} = datetime, _timezone \\ "Asia/Kolkata") do
    # For now, assume UTC times and add IST offset manually (+5:30)
    ist_datetime = DateTime.add(datetime, 5 * 3600 + 30 * 60, :second)
    Calendar.strftime(ist_datetime, "%I:%M %p IST")
  end
end