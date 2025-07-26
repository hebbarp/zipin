defmodule CreamSocial.Social.Channel do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Accounts.User
  alias CreamSocial.Social.ChannelPost

  schema "channels" do
    field :name, :string
    field :description, :string
    field :slug, :string
    field :banner_image, :string
    field :privacy, :string, default: "public"
    field :posts_count, :integer, default: 0
    field :followers_count, :integer, default: 0
    field :active, :boolean, default: true

    belongs_to :user, User
    has_many :channel_posts, ChannelPost
    has_many :posts, through: [:channel_posts, :post]

    timestamps()
  end

  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:name, :description, :slug, :banner_image, :privacy, :active, :user_id])
    |> validate_required([:name, :slug, :user_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "must be lowercase letters, numbers, and dashes only")
    |> validate_inclusion(:privacy, ["public", "private", "invite_only"])
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:user_id)
  end
end