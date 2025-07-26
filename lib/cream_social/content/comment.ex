defmodule CreamSocial.Content.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Accounts.User
  alias CreamSocial.Content.{Post, Comment}

  schema "comments" do
    field :content, :string
    field :deleted_at, :naive_datetime

    belongs_to :user, User
    belongs_to :post, Post
    belongs_to :parent, Comment, foreign_key: :parent_id

    has_many :replies, Comment, foreign_key: :parent_id

    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :user_id, :post_id, :parent_id])
    |> validate_required([:content, :user_id, :post_id])
    |> validate_length(:content, min: 1, max: 1000)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:parent_id)
  end
end