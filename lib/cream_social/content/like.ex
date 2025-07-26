defmodule CreamSocial.Content.Like do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Accounts.User
  alias CreamSocial.Content.Post

  schema "likes" do
    field :reaction_type, :string, default: "like"

    belongs_to :user, User
    belongs_to :post, Post

    timestamps()
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:reaction_type, :user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> validate_inclusion(:reaction_type, ["like", "love", "laugh", "angry", "sad"])
    |> unique_constraint([:user_id, :post_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
  end
end