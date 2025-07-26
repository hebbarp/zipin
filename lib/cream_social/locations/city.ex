defmodule CreamSocial.Locations.City do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Accounts.User
  alias CreamSocial.Places.Place
  alias CreamSocial.Events.Event

  schema "cities" do
    field :name, :string
    field :slug, :string
    field :state, :string
    field :country, :string
    field :timezone, :string
    
    # Localization
    field :primary_language, :string
    field :supported_languages, {:array, :string}
    
    # City configuration
    field :areas, {:array, :string}
    field :cultural_keywords, {:array, :string}
    field :hashtags, {:array, :string}
    
    # Status and metadata
    field :active, :boolean
    field :launched_at, :utc_datetime
    field :config, :map
    
    # Associations
    has_many :users, User
    has_many :places, Place
    has_many :events, Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(city, attrs) do
    city
    |> cast(attrs, [
      :name, :slug, :state, :country, :timezone, :primary_language, 
      :supported_languages, :areas, :cultural_keywords, :hashtags,
      :active, :launched_at, :config
    ])
    |> validate_required([:name, :slug, :state, :country])
    |> validate_format(:slug, ~r/^[a-z0-9_-]+$/, message: "must be lowercase with underscores or dashes only")
    |> validate_inclusion(:primary_language, ["en", "hi", "kn", "ta", "te", "ml", "mr", "gu"])
    |> unique_constraint(:slug)
  end

  # Predefined city configurations
  def city_configs do
    %{
      "bangalore" => %{
        name: "Bangalore",
        slug: "bangalore", 
        state: "Karnataka",
        country: "India",
        timezone: "Asia/Kolkata",
        primary_language: "en",
        supported_languages: ["en", "kn", "hi"],
        areas: [
          "koramangala", "indiranagar", "whitefield", "electronic_city", 
          "jayanagar", "malleswaram", "rajajinagar", "banashankari", 
          "btm_layout", "hsr_layout", "marathahalli", "sarjapur",
          "bellandur", "hebbal", "mg_road", "brigade_road"
        ],
        cultural_keywords: [
          "rcb", "royal_challengers", "virat_kohli", "namma_metro", 
          "silk_board", "chinnaswamy", "masala_dosa", "filter_coffee",
          "bengaluru", "bangalorean", "traffic", "weather"
        ],
        hashtags: [
          "#bangalore", "#bengaluru", "#nammabengaluru", "#rcb", 
          "#koramangala", "#indiranagar", "#nammatrafficpolice"
        ]
      },
      "mumbai" => %{
        name: "Mumbai", 
        slug: "mumbai",
        state: "Maharashtra",
        country: "India",
        timezone: "Asia/Kolkata",
        primary_language: "hi",
        supported_languages: ["hi", "mr", "en"],
        areas: [
          "bandra", "juhu", "andheri", "powai", "lower_parel", 
          "colaba", "fort", "worli", "malad", "goregaon",
          "borivali", "thane", "navi_mumbai"
        ],
        cultural_keywords: [
          "mumbai_indians", "bollywood", "marine_drive", "gateway_of_india",
          "vada_pav", "local_train", "mumbaikar", "maximum_city"
        ],
        hashtags: [
          "#mumbai", "#mumbaikar", "#bollywood", "#marinedrive", 
          "#vadapav", "#localtrain", "#maximumcity"
        ]
      },
      "delhi" => %{
        name: "Delhi",
        slug: "delhi", 
        state: "Delhi",
        country: "India", 
        timezone: "Asia/Kolkata",
        primary_language: "hi",
        supported_languages: ["hi", "en", "pu"],
        areas: [
          "connaught_place", "khan_market", "saket", "gurgaon",
          "noida", "karol_bagh", "lajpat_nagar", "chandni_chowk",
          "rohini", "dwarka", "vasant_kunj"
        ],
        cultural_keywords: [
          "delhi_capitals", "red_fort", "india_gate", "metro",
          "chole_bhature", "paranthe_wali_gali", "delhiite"
        ],
        hashtags: [
          "#delhi", "#delhigram", "#indiagate", "#redfort",
          "#cholebhature", "#delhimetro", "#dillihaat"
        ]
      }
    }
  end

  def get_city_config(slug) do
    city_configs()[slug]
  end

  def available_cities do
    city_configs()
    |> Enum.map(fn {slug, config} -> {config.name, slug} end)
    |> Enum.sort()
  end

  def display_name(city) do
    case city do
      %__MODULE__{name: name} -> name
      slug when is_binary(slug) -> 
        case get_city_config(slug) do
          nil -> String.capitalize(slug)
          config -> config.name
        end
      _ -> "Unknown City"
    end
  end

  def area_display_name(area) when is_binary(area) do
    area
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end