defmodule CreamSocial.Repo.Migrations.CreatePlaceReviews do
  use Ecto.Migration

  def change do
    create table(:place_reviews) do
      add :place_id, references(:places, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      
      add :rating, :integer, null: false  # 1-5 stars
      add :title, :string
      add :content, :text
      
      # Review aspects (optional ratings for different aspects)
      add :food_rating, :integer          # 1-5 for restaurants
      add :service_rating, :integer       # 1-5 for service quality
      add :ambiance_rating, :integer      # 1-5 for atmosphere
      add :value_rating, :integer         # 1-5 for value for money
      add :wifi_rating, :integer          # 1-5 for wifi quality (cafes)
      
      # Review metadata
      add :visit_date, :date
      add :recommended, :boolean, default: true
      add :verified_visit, :boolean, default: false  # Future: location verification
      
      # Community engagement
      add :helpful_count, :integer, default: 0
      add :unhelpful_count, :integer, default: 0
      
      # Status
      add :status, :string, default: "active"  # active, hidden, flagged
      
      timestamps(type: :utc_datetime)
    end

    create index(:place_reviews, [:place_id])
    create index(:place_reviews, [:user_id])
    create index(:place_reviews, [:place_id, :rating])
    create index(:place_reviews, [:rating])
    create index(:place_reviews, [:status])
    create unique_index(:place_reviews, [:place_id, :user_id], name: :unique_place_user_review)
  end
end