defmodule CreamSocial.Social.Follow do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Accounts.User

  schema "follows" do
    field :status, :string, default: "active"
    field :notifications_enabled, :boolean, default: true

    belongs_to :follower, User, foreign_key: :follower_id
    belongs_to :followed, User, foreign_key: :followed_id

    timestamps()
  end

  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:status, :notifications_enabled, :follower_id, :followed_id])
    |> validate_required([:follower_id, :followed_id])
    |> validate_inclusion(:status, ["active", "blocked", "muted"])
    |> validate_different_users()
    |> unique_constraint([:follower_id, :followed_id])
    |> foreign_key_constraint(:follower_id)
    |> foreign_key_constraint(:followed_id)
  end

  defp validate_different_users(changeset) do
    follower_id = get_field(changeset, :follower_id)
    followed_id = get_field(changeset, :followed_id)

    if follower_id && followed_id && follower_id == followed_id do
      add_error(changeset, :followed_id, "cannot follow yourself")
    else
      changeset
    end
  end
end