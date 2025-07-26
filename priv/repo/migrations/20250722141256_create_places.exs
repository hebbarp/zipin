defmodule CreamSocial.Repo.Migrations.CreatePlaces do
  use Ecto.Migration

  def change do
    create table(:places) do
      add :name, :string, null: false
      add :description, :text
      add :category, :string, null: false  # restaurant, cafe, attraction, shopping, service
      add :subcategory, :string           # south_indian, coworking, park, electronics, etc.
      
      # Location data
      add :address, :text
      add :area, :string, null: false      # koramangala, indiranagar, whitefield, etc.
      add :latitude, :decimal, precision: 10, scale: 8
      add :longitude, :decimal, precision: 11, scale: 8
      add :pincode, :string
      
      # Contact & Business Info
      add :phone, :string
      add :website, :string
      add :email, :string
      add :hours, :map                     # JSON: {"monday": "9:00-22:00", "tuesday": "9:00-22:00", ...}
      add :price_range, :string            # budget, mid_range, expensive
      
      # Features & Amenities
      add :wifi_available, :boolean, default: false
      add :parking_available, :boolean, default: false
      add :wheelchair_accessible, :boolean, default: false
      add :outdoor_seating, :boolean, default: false
      add :accepts_cards, :boolean, default: true
      add :amenities, {:array, :string}, default: []  # ["wifi", "parking", "ac", "live_music"]
      
      # Google Places Integration
      add :google_place_id, :string
      add :google_rating, :decimal, precision: 3, scale: 2
      add :google_total_ratings, :integer
      add :google_price_level, :integer    # 0-4 scale from Google
      
      # Community Data
      add :community_rating, :decimal, precision: 3, scale: 2
      add :community_total_ratings, :integer, default: 0
      add :verified, :boolean, default: false
      add :featured, :boolean, default: false
      
      # Metadata
      add :status, :string, default: "active"  # active, inactive, closed
      add :created_by_id, references(:users, on_delete: :nilify_all)
      add :last_verified_at, :utc_datetime
      
      timestamps(type: :utc_datetime)
    end

    create index(:places, [:area])
    create index(:places, [:category])
    create index(:places, [:category, :area])
    create index(:places, [:latitude, :longitude])
    create index(:places, [:featured, :status])
    create index(:places, [:community_rating])
    create unique_index(:places, [:google_place_id], where: "google_place_id IS NOT NULL")
  end
end