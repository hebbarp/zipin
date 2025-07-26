defmodule CreamSocial.Social.ChannelPost do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Content.Post
  alias CreamSocial.Social.Channel

  schema "channel_posts" do
    field :position, :integer, default: 0

    belongs_to :channel, Channel
    belongs_to :post, Post

    timestamps()
  end

  def changeset(channel_post, attrs) do
    channel_post
    |> cast(attrs, [:position, :channel_id, :post_id])
    |> validate_required([:channel_id, :post_id])
    |> unique_constraint([:channel_id, :post_id])
    |> foreign_key_constraint(:channel_id)
    |> foreign_key_constraint(:post_id)
  end
end