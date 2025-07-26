defmodule CreamSocial.Places.Place do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Places.PlaceReview
  alias CreamSocial.Accounts.User
  alias CreamSocial.Locations.City

  schema "places" do
    field :name, :string
    field :description, :string
    field :category, :string
    field :subcategory, :string
    
    # Location data
    field :address, :string
    field :area, :string
    field :latitude, :decimal
    field :longitude, :decimal
    field :pincode, :string
    
    # Contact & Business Info
    field :phone, :string
    field :website, :string
    field :email, :string
    field :hours, :map
    field :price_range, :string
    
    # Features & Amenities
    field :wifi_available, :boolean, default: false
    field :parking_available, :boolean, default: false
    field :wheelchair_accessible, :boolean, default: false
    field :outdoor_seating, :boolean, default: false
    field :accepts_cards, :boolean, default: true
    field :amenities, {:array, :string}, default: []
    
    # Google Places Integration
    field :google_place_id, :string
    field :google_rating, :decimal
    field :google_total_ratings, :integer
    field :google_price_level, :integer
    
    # Community Data
    field :community_rating, :decimal
    field :community_total_ratings, :integer, default: 0
    field :verified, :boolean, default: false
    field :featured, :boolean, default: false
    
    # Metadata
    field :status, :string, default: "active"
    field :last_verified_at, :utc_datetime
    
    # Images
    field :image_url, :string
    field :images, :map, default: %{}
    
    # Associations
    belongs_to :created_by, User
    belongs_to :city, City
    has_many :reviews, PlaceReview

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(place, attrs) do
    place
    |> cast(attrs, [
      :name, :description, :category, :subcategory, :address, :area,
      :latitude, :longitude, :pincode, :phone, :website, :email,
      :hours, :price_range, :wifi_available, :parking_available,
      :wheelchair_accessible, :outdoor_seating, :accepts_cards, :amenities,
      :google_place_id, :google_rating, :google_total_ratings, :google_price_level,
      :community_rating, :community_total_ratings, :verified, :featured,
      :status, :last_verified_at, :created_by_id, :image_url, :images
    ])
    |> validate_required([:name, :category, :area])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_length(:address, max: 200)
    |> validate_inclusion(:category, ["restaurant", "cafe", "attraction", "shopping", "service"])
    |> validate_inclusion(:price_range, ["budget", "mid_range", "expensive"])
    |> validate_inclusion(:status, ["active", "inactive", "closed"])
    |> validate_number(:latitude, greater_than: -90, less_than: 90)
    |> validate_number(:longitude, greater_than: -180, less_than: 180)
    |> validate_number(:google_rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
    |> validate_number(:community_rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
    |> validate_format(:phone, ~r/^[\+\d\s\-\(\)]+$/, message: "must be a valid phone number")
    |> validate_format(:website, ~r/^https?:\/\//, message: "must start with http:// or https://")
    |> unique_constraint(:google_place_id)
    |> unique_constraint([:name, :area], message: "Place already exists in this area")
  end

  @bangalore_areas [
    "koramangala", "indiranagar", "whitefield", "electronic_city", "jayanagar",
    "malleswaram", "rajajinagar", "banashankari", "btm_layout", "hsr_layout",
    "marathahalli", "sarjapur", "bellandur", "hebbal", "mg_road", "brigade_road",
    "commercial_street", "ulsoor", "frazer_town", "richmond_town", "basavanagudi",
    "chickpet", "majestic", "sadashivanagar", "vasanth_nagar", "cubbon_park",
    "vidhana_soudha", "bangalore_cantonment", "new_bel_road", "rt_nagar", "other"
  ]

  def bangalore_areas, do: @bangalore_areas

  @categories %{
    "restaurant" => %{
      name: "Restaurants",
      icon: "🍛",
      subcategories: [
        "south_indian", "north_indian", "chinese", "continental", "fast_food",
        "biryani", "pizza", "desserts", "street_food", "fine_dining", "buffet"
      ]
    },
    "cafe" => %{
      name: "Cafes",
      icon: "☕",
      subcategories: [
        "coffee_shop", "bakery", "tea_house", "coworking_cafe", "dessert_cafe",
        "outdoor_cafe", "chain_cafe", "local_cafe", "roastery"
      ]
    },
    "attraction" => %{
      name: "Attractions",
      icon: "🏛️",
      subcategories: [
        "park", "museum", "temple", "palace", "monument", "lake", "garden",
        "shopping_mall", "market", "art_gallery", "theatre", "stadium"
      ]
    },
    "shopping" => %{
      name: "Shopping",
      icon: "🛍️",
      subcategories: [
        "mall", "market", "electronics", "clothing", "books", "home_decor",
        "jewelry", "handicrafts", "street_market", "brand_store"
      ]
    },
    "service" => %{
      name: "Services",
      icon: "🔧",
      subcategories: [
        "salon", "spa", "gym", "hospital", "pharmacy", "bank", "atm",
        "petrol_pump", "auto_repair", "mobile_repair", "laundry", "photography"
      ]
    }
  }

  def categories, do: @categories

  def category_options do
    @categories
    |> Enum.map(fn {key, value} -> {value.name, key} end)
  end

  def subcategory_options(category) do
    case @categories[category] do
      nil -> []
      category_info -> 
        category_info.subcategories
        |> Enum.map(fn sub -> {String.replace(sub, "_", " ") |> String.capitalize(), sub} end)
    end
  end

  def area_options do
    @bangalore_areas
    |> Enum.map(fn area -> {String.replace(area, "_", " ") |> String.capitalize(), area} end)
  end
end