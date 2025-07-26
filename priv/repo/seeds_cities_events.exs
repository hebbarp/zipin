# Script to seed cities and sample events
alias CreamSocial.{Repo, Locations, Events, Accounts}
alias CreamSocial.Locations.City
alias CreamSocial.Events.Event

# Helper function to create truncated datetime
defmodule SeedHelper do
  def datetime_plus(days, hours \\ 0) do
    DateTime.utc_now() 
    |> DateTime.add(days, :day) 
    |> DateTime.add(hours * 3600, :second) 
    |> DateTime.truncate(:second)
  end
end

# Create Bangalore city if it doesn't exist
bangalore_config = City.get_city_config("bangalore")

bangalore = 
  case Repo.get_by(City, slug: "bangalore") do
    nil ->
      {:ok, city} = Repo.insert(%City{
        name: bangalore_config.name,
        slug: bangalore_config.slug,
        state: bangalore_config.state,
        country: bangalore_config.country,
        timezone: bangalore_config.timezone,
        primary_language: bangalore_config.primary_language,
        supported_languages: bangalore_config.supported_languages,
        areas: bangalore_config.areas,
        cultural_keywords: bangalore_config.cultural_keywords,
        hashtags: bangalore_config.hashtags,
        active: true,
        launched_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      city
    city -> city
  end

# Get first user as event organizer (you might need to create a user first)
organizer = Repo.all(Accounts.User) |> List.first()

if organizer do
  # Sample Tech Events
  tech_events = [
    %{
      title: "Bangalore DevOps Meetup - Kubernetes Deep Dive",
      description: "Join us for an evening of learning about Kubernetes best practices, monitoring, and scaling strategies. Perfect for DevOps engineers and developers.",
      category: "tech",
      subcategory: "meetup",
      start_datetime: SeedHelper.datetime_plus(7, 19), # 7 days from now, 7 PM
      end_datetime: SeedHelper.datetime_plus(7, 21), # 9 PM
      venue_name: "WeWork Koramangala",
      venue_address: "WeWork Prestige Atlanta, 80 Feet Main Rd, 4th Block, Koramangala 1 Block, Koramangala, Bengaluru",
      area: "koramangala",
      max_attendees: 100,
      is_free: true,
      organizer_id: organizer.id,
      city_id: bangalore.id,
      featured: true,
      tags: ["kubernetes", "devops", "tech", "bangalore"]
    },
    %{
      title: "AI/ML Workshop: Building LLM Applications",
      description: "Hands-on workshop on building applications with Large Language Models. Bring your laptop! We'll cover prompt engineering, fine-tuning, and RAG.",
      category: "tech", 
      subcategory: "workshop",
      start_datetime: SeedHelper.datetime_plus(10, 14), # 10 days, 2 PM
      end_datetime: SeedHelper.datetime_plus(10, 17), # 5 PM
      venue_name: "Microsoft Bangalore",
      venue_address: "Microsoft India Development Center, Vigyan, SDF Building, EPIP Area, Whitefield, Bengaluru",
      area: "whitefield",
      max_attendees: 50,
      is_free: false,
      ticket_price: Decimal.new("500.00"),
      organizer_id: organizer.id,
      city_id: bangalore.id,
      tags: ["ai", "ml", "llm", "workshop", "bangalore"]
    }
  ]

  # Sample Social/Networking Events
  social_events = [
    %{
      title: "Bangalore Tech Professionals Networking Night",
      description: "Connect with fellow tech professionals over drinks and conversations. Perfect for developers, designers, PMs, and startup folks.",
      category: "social",
      subcategory: "networking",
      start_datetime: SeedHelper.datetime_plus(5, 19), # 5 days, 7 PM
      end_datetime: SeedHelper.datetime_plus(5, 22), # 10 PM
      venue_name: "Toit Brewpub",
      venue_address: "298, 100 Feet Rd, Indiranagar, Bengaluru",
      area: "indiranagar", 
      max_attendees: 150,
      is_free: false,
      ticket_price: Decimal.new("800.00"),
      organizer_id: organizer.id,
      city_id: bangalore.id,
      featured: true,
      tags: ["networking", "tech", "professionals", "bangalore", "drinks"]
    }
  ]

  # Sample Sports Events
  sports_events = [
    %{
      title: "Sunday Morning Cricket Match - All Levels Welcome",
      description: "Friendly cricket match every Sunday morning. All skill levels welcome! We provide equipment. Just bring your enthusiasm.",
      category: "sports",
      subcategory: "cricket",
      start_datetime: SeedHelper.datetime_plus(6, 8), # Next Sunday, 8 AM
      end_datetime: SeedHelper.datetime_plus(6, 12), # 12 PM
      venue_name: "Cubbon Park Ground",
      venue_address: "Cubbon Park, Kasturba Road, Ambedkar Veedhi, Bengaluru",
      area: "mg_road",
      max_attendees: 22,
      is_free: true,
      recurring: true,
      recurring_pattern: "weekly",
      organizer_id: organizer.id,
      city_id: bangalore.id,
      tags: ["cricket", "sports", "sunday", "morning", "bangalore"]
    }
  ]

  # Sample Food Events  
  food_events = [
    %{
      title: "Street Food Tour: VV Puram Food Street",
      description: "Guided tour through Bangalore's famous VV Puram Food Street. Taste 8-10 local delicacies. Vegetarian options available.",
      category: "food",
      subcategory: "food_tour",
      start_datetime: SeedHelper.datetime_plus(8, 18), # 8 days, 6 PM
      end_datetime: SeedHelper.datetime_plus(8, 21), # 9 PM
      venue_name: "VV Puram Food Street",
      venue_address: "Vijaya Vittala Food Street, Basavanagudi, Bengaluru",
      area: "basavanagudi",
      max_attendees: 25,
      is_free: false,
      ticket_price: Decimal.new("400.00"),
      organizer_id: organizer.id,
      city_id: bangalore.id,
      featured: true,
      tags: ["food", "street_food", "local", "tour", "bangalore"]
    }
  ]

  # Insert all events
  all_events = tech_events ++ social_events ++ sports_events ++ food_events
  
  for event_attrs <- all_events do
    case Events.create_event(event_attrs) do
      {:ok, event} ->
        IO.puts("Created event: #{event.title}")
      {:error, changeset} ->
        IO.puts("Failed to create event: #{inspect(changeset.errors)}")
    end
  end

  IO.puts("Seeded #{length(all_events)} events for Bangalore!")
else
  IO.puts("No users found. Please create a user first before running this seed script.")
end