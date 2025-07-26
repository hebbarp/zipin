defmodule CreamSocial.Content.Post do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias CreamSocial.Accounts.User
  alias CreamSocial.Content.{Post, Category, Like, Bookmark, LinkPreview}
  alias CreamSocial.Social.ChannelPost

  schema "posts" do
    field :content, :string
    field :media_paths, {:array, :string}, default: []
    field :metadata, :map, default: %{}
    field :visibility, :string, default: "public"
    field :scheduled_at, :naive_datetime
    field :published_at, :naive_datetime
    field :edited_at, :naive_datetime
    field :deleted_at, :naive_datetime
    field :likes_count, :integer, default: 0
    field :comments_count, :integer, default: 0
    field :shares_count, :integer, default: 0
    field :views_count, :integer, default: 0

    belongs_to :user, User
    belongs_to :parent, Post, foreign_key: :parent_id
    belongs_to :shared_post, Post, foreign_key: :shared_post_id
    belongs_to :category, Category

    has_many :replies, Post, foreign_key: :parent_id
    has_many :shares, Post, foreign_key: :shared_post_id
    has_many :likes, Like
    has_many :bookmarks, Bookmark
    has_many :channel_posts, ChannelPost
    many_to_many :link_previews, LinkPreview, join_through: "post_link_previews"

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:content, :media_paths, :metadata, :visibility, 
                    :scheduled_at, :published_at, :user_id, :parent_id, :shared_post_id, :category_id])
    |> validate_content_for_shares()
    |> validate_length(:content, max: 5000)
    |> validate_inclusion(:visibility, ["public", "private", "followers_only"])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:parent_id)
    |> foreign_key_constraint(:shared_post_id)
    |> foreign_key_constraint(:category_id)
    |> maybe_set_published_at()
  end

  defp validate_content_for_shares(changeset) do
    shared_post_id = get_field(changeset, :shared_post_id)
    content = get_field(changeset, :content)
    
    if shared_post_id && (is_nil(content) || content == "" || String.trim(content) == "") do
      # For reposts, ensure we have at least a single space as content
      changeset
      |> put_change(:content, " ")
      |> validate_required([:user_id])
    else
      validate_required(changeset, [:content, :user_id])
      |> validate_length(:content, min: 1)
    end
  end

  def update_changeset(post, attrs) do
    changeset = 
      post
      |> cast(attrs, [:content, :media_paths, :metadata, :visibility, :category_id, :deleted_at])
      |> maybe_set_edited_at(attrs)
    
    # Only validate content if we're not deleting the post
    if Map.has_key?(attrs, :deleted_at) or Map.has_key?(attrs, "deleted_at") do
      changeset
    else
      changeset
      |> validate_required([:content])
      |> validate_length(:content, min: 1, max: 5000)
      |> validate_inclusion(:visibility, ["public", "private", "followers_only"])
    end
  end

  defp maybe_set_edited_at(changeset, attrs) do
    # Only set edited_at if we're not deleting the post
    if Map.has_key?(attrs, :deleted_at) or Map.has_key?(attrs, "deleted_at") do
      changeset
    else
      put_change(changeset, :edited_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    end
  end

  defp maybe_set_published_at(changeset) do
    if get_field(changeset, :published_at) do
      changeset
    else
      put_change(changeset, :published_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    end
  end

  def published_query do
    from p in Post,
      where: not is_nil(p.published_at) and is_nil(p.deleted_at)
  end

  def public_query do
    from p in Post,
      where: p.visibility == "public"
  end

  def with_user_query do
    from p in Post,
      preload: [:user]
  end

  def increment_likes_count(post) do
    from(p in Post, where: p.id == ^post.id)
    |> CreamSocial.Repo.update_all(inc: [likes_count: 1])
  end

  def decrement_likes_count(post) do
    from(p in Post, where: p.id == ^post.id)
    |> CreamSocial.Repo.update_all(inc: [likes_count: -1])
  end

  def increment_views_count(post) do
    from(p in Post, where: p.id == ^post.id)
    |> CreamSocial.Repo.update_all(inc: [views_count: 1])
  end
end