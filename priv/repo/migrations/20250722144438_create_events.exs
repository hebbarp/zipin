defmodule CreamSocial.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      # Basic Info
      add :title, :string, null: false
      add :description, :text
      add :category, :string, null: false    # tech, social, sports, culture, professional
      add :subcategory, :string             # meetup, conference, workshop, networking, etc.
      add :slug, :string
      
      # Date & Time
      add :start_datetime, :utc_datetime, null: false
      add :end_datetime, :utc_datetime
      add :timezone, :string, default: "Asia/Kolkata"
      add :recurring, :boolean, default: false
      add :recurring_pattern, :string       # weekly, monthly, etc.
      
      # Location
      add :venue_name, :string
      add :venue_address, :text
      add :area, :string
      add :latitude, :decimal, precision: 10, scale: 8
      add :longitude, :decimal, precision: 11, scale: 8
      add :is_online, :boolean, default: false
      add :online_link, :string
      
      # Capacity & Pricing  
      add :max_attendees, :integer
      add :current_attendees, :integer, default: 0
      add :is_free, :boolean, default: true
      add :ticket_price, :decimal, precision: 10, scale: 2
      add :currency, :string, default: "INR"
      
      # Event Management
      add :status, :string, default: "active"    # active, cancelled, completed
      add :visibility, :string, default: "public" # public, private, invite_only
      add :requires_approval, :boolean, default: false
      add :tags, {:array, :string}, default: []
      
      # Social Features
      add :featured, :boolean, default: false
      add :likes_count, :integer, default: 0
      add :shares_count, :integer, default: 0
      add :views_count, :integer, default: 0
      
      # Relations
      add :organizer_id, references(:users, on_delete: :delete_all), null: false
      add :city_id, references(:cities, on_delete: :delete_all)
      add :place_id, references(:places, on_delete: :nilify_all)  # Optional place association

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:organizer_id])
    create index(:events, [:city_id])
    create index(:events, [:place_id])
    create index(:events, [:category])
    create index(:events, [:area])
    create index(:events, [:start_datetime])
    create index(:events, [:status, :visibility])
    create index(:events, [:featured, :start_datetime])
    create unique_index(:events, [:slug], where: "slug IS NOT NULL")
  end
end
