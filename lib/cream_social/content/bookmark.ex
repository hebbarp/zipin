defmodule CreamSocial.Content.Bookmark do
  use Ecto.Schema
  import Ecto.Changeset
  alias CreamSocial.Accounts.User
  alias CreamSocial.Content.Post

  schema "bookmarks" do
    field :collection_name, :string
    field :notes, :string

    belongs_to :user, User
    belongs_to :post, Post

    timestamps()
  end

  def changeset(bookmark, attrs) do
    bookmark
    |> cast(attrs, [:collection_name, :notes, :user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> unique_constraint([:user_id, :post_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
  end
end