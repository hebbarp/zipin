defmodule CreamSocial.Places.PlaceReview do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Places.Place
  alias CreamSocial.Accounts.User

  schema "place_reviews" do
    field :rating, :integer
    field :title, :string
    field :content, :string
    
    # Review aspects (optional ratings for different aspects)
    field :food_rating, :integer
    field :service_rating, :integer
    field :ambiance_rating, :integer
    field :value_rating, :integer
    field :wifi_rating, :integer
    
    # Review metadata
    field :visit_date, :date
    field :recommended, :boolean, default: true
    field :verified_visit, :boolean, default: false
    
    # Community engagement
    field :helpful_count, :integer, default: 0
    field :unhelpful_count, :integer, default: 0
    
    # Status
    field :status, :string, default: "active"
    
    # Associations
    belongs_to :place, Place
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [
      :rating, :title, :content, :food_rating, :service_rating,
      :ambiance_rating, :value_rating, :wifi_rating, :visit_date,
      :recommended, :verified_visit, :helpful_count, :unhelpful_count,
      :status, :place_id, :user_id
    ])
    |> validate_required([:rating, :place_id, :user_id])
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:food_rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:service_rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:ambiance_rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:value_rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:wifi_rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_inclusion(:status, ["active", "hidden", "flagged"])
    |> validate_length(:title, max: 200)
    |> validate_length(:content, max: 2000)
    |> unique_constraint([:place_id, :user_id], name: :unique_place_user_review)
  end

  def rating_text(rating) do
    case rating do
      5 -> "Excellent"
      4 -> "Good"
      3 -> "Average"
      2 -> "Poor"
      1 -> "Terrible"
      _ -> "Not rated"
    end
  end

  def rating_stars(rating) when is_integer(rating) do
    full_stars = String.duplicate("⭐", rating)
    empty_stars = String.duplicate("☆", 5 - rating)
    full_stars <> empty_stars
  end

  def rating_stars(_), do: "☆☆☆☆☆"
end