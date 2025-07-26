defmodule CreamSocial.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false
  alias CreamSocial.Repo
  alias CreamSocial.Content.{Post, Like, Bookmark, Comment, LinkExtractor}
  alias CreamSocial.Accounts.User

  # Posts

  def list_posts do
    from(p in Post,
      where: not is_nil(p.published_at) and is_nil(p.deleted_at) and p.visibility == "public" and is_nil(p.parent_id),
      preload: [:user, :replies, :shared_post, :link_previews],
      order_by: [desc: p.published_at]
    )
    |> Repo.all()
    |> Enum.map(fn post ->
      # Filter out deleted replies
      filtered_replies = Enum.filter(post.replies, fn reply -> is_nil(reply.deleted_at) end)
      
      # Load shared post user if it exists
      shared_post = if post.shared_post do
        post.shared_post |> Repo.preload(:user)
      else
        nil
      end
      
      %{post | replies: filtered_replies, shared_post: shared_post}
    end)
  end

  def list_user_posts(%User{} = user) do
    from(p in Post,
      where: p.user_id == ^user.id and not is_nil(p.published_at) and is_nil(p.deleted_at),
      preload: [:user],
      order_by: [desc: p.published_at]
    )
    |> Repo.all()
  end

  def get_post!(id) do
    from(p in Post,
      where: p.id == ^id,
      preload: [:user, :link_previews]
    )
    |> Repo.one!()
  end

  def get_post_with_replies!(id) do
    post = 
      from(p in Post,
        where: p.id == ^id,
        preload: [:user, :link_previews]
      )
      |> Repo.one!()
    
    # Load all replies recursively
    replies = load_all_replies(id)
    %{post | replies: replies}
  end

  def get_post(id) do
    from(p in Post,
      where: p.id == ^id,
      preload: [:user, :link_previews]
    )
    |> Repo.one()
  end

  def create_post(attrs \\ %{}) do
    case %Post{}
         |> Post.changeset(attrs)
         |> Repo.insert() do
      {:ok, post} ->
        # Extract and associate link previews in background
        Task.start(fn -> extract_links_for_post(post) end)
        {:ok, post}
      error ->
        error
    end
  end
  
  defp extract_links_for_post(%Post{} = post) do
    if post.content do
      urls = LinkExtractor.extract_links_from_text(post.content)
      
      Enum.each(urls, fn url ->
        case LinkExtractor.extract_and_cache(url) do
          {:ok, link_preview} ->
            # Associate the link preview with the post
            Repo.insert_all("post_link_previews", [
              %{
                post_id: post.id,
                link_preview_id: link_preview.id
              }
            ], on_conflict: :nothing)
            
            # Broadcast the update to refresh the UI
            Phoenix.PubSub.broadcast(
              CreamSocial.PubSub,
              "post_updates",
              {:link_preview_added, post.id, link_preview}
            )
          _error ->
            # Silently ignore extraction errors
            :ok
        end
      end)
    end
  end

  def update_post(%Post{} = post, attrs) do
    post
    |> Post.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_post(%Post{} = post) do
    # Use soft delete instead of hard delete to preserve data integrity
    post
    |> Post.update_changeset(%{deleted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)})
    |> Repo.update()
  end

  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def increment_post_views(%Post{} = post) do
    Post.increment_views_count(post)
    {:ok, %{post | views_count: post.views_count + 1}}
  end

  # Likes

  def toggle_like(%User{} = user, %Post{} = post) do
    case get_like(user, post) do
      nil -> create_like(user, post)
      like -> delete_like(like)
    end
  end

  def create_like(%User{} = user, %Post{} = post) do
    like_attrs = %{user_id: user.id, post_id: post.id}

    result = 
      %Like{}
      |> Like.changeset(like_attrs)
      |> Repo.insert()

    case result do
      {:ok, like} ->
        Post.increment_likes_count(post)
        {:ok, like}
      error ->
        error
    end
  end

  def delete_like(%Like{} = like) do
    result = Repo.delete(like)

    case result do
      {:ok, deleted_like} ->
        post = get_post!(deleted_like.post_id)
        Post.decrement_likes_count(post)
        {:ok, deleted_like}
      error ->
        error
    end
  end

  def get_like(%User{} = user, %Post{} = post) do
    Repo.get_by(Like, user_id: user.id, post_id: post.id)
  end

  def user_liked_post?(%User{} = user, %Post{} = post) do
    get_like(user, post) != nil
  end

  # Bookmarks

  def toggle_bookmark(%User{} = user, %Post{} = post) do
    case get_bookmark(user, post) do
      nil -> create_bookmark(user, post)
      bookmark -> delete_bookmark(bookmark)
    end
  end

  def create_bookmark(%User{} = user, %Post{} = post, attrs \\ %{}) do
    bookmark_attrs = Map.merge(attrs, %{user_id: user.id, post_id: post.id})

    %Bookmark{}
    |> Bookmark.changeset(bookmark_attrs)
    |> Repo.insert()
  end

  def delete_bookmark(%Bookmark{} = bookmark) do
    Repo.delete(bookmark)
  end

  def get_bookmark(%User{} = user, %Post{} = post) do
    Repo.get_by(Bookmark, user_id: user.id, post_id: post.id)
  end

  def user_bookmarked_post?(%User{} = user, %Post{} = post) do
    get_bookmark(user, post) != nil
  end

  def list_user_bookmarks(%User{} = user) do
    from(b in Bookmark,
      where: b.user_id == ^user.id,
      join: p in assoc(b, :post),
      preload: [post: {p, [:user]}],
      order_by: [desc: b.inserted_at]
    )
    |> Repo.all()
  end

  # Comments

  def list_post_comments(%Post{} = post) do
    from(c in Comment,
      where: c.post_id == ^post.id and is_nil(c.deleted_at) and is_nil(c.parent_id),
      preload: [:user, replies: [:user]],
      order_by: [asc: c.inserted_at]
    )
    |> Repo.all()
  end

  def create_comment(attrs \\ %{}) do
    result = 
      %Comment{}
      |> Comment.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, comment} ->
        # Increment comments count on post
        post = get_post!(comment.post_id)
        from(p in Post, where: p.id == ^post.id)
        |> Repo.update_all(inc: [comments_count: 1])
        {:ok, comment}
      error ->
        error
    end
  end

  def delete_comment(%Comment{} = comment) do
    result = 
      comment
      |> Comment.changeset(%{deleted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)})
      |> Repo.update()

    case result do
      {:ok, deleted_comment} ->
        # Decrement comments count on post
        post = get_post!(deleted_comment.post_id)
        from(p in Post, where: p.id == ^post.id)
        |> Repo.update_all(inc: [comments_count: -1])
        {:ok, deleted_comment}
      error ->
        error
    end
  end

  # Recursively load all replies for a post
  defp load_all_replies(parent_id) do
    from(p in Post,
      where: p.parent_id == ^parent_id and is_nil(p.deleted_at),
      preload: [:user],
      order_by: [asc: p.inserted_at]
    )
    |> Repo.all()
    |> Enum.map(fn reply ->
      # Recursively load replies for this reply
      nested_replies = load_all_replies(reply.id)
      %{reply | replies: nested_replies}
    end)
  end

  # Helper function to count total replies recursively
  def count_all_replies(replies) do
    Enum.reduce(replies, 0, fn reply, acc ->
      acc + 1 + count_all_replies(reply.replies)
    end)
  end

  # Sharing functionality
  def share_post(user, post, share_type, opts \\ %{})

  def share_post(%User{} = user, %Post{} = post, share_type, opts) do
    case share_type do
      :repost -> create_repost(user, post, opts)
      :quote -> create_quote_share(user, post, opts)
      :direct_message -> share_via_dm(user, post, opts)
      :copy_link -> generate_share_link(post)
    end
  end

  # Handle copy_link case with nil user
  def share_post(nil, %Post{} = post, :copy_link, _opts) do
    generate_share_link(post)
  end

  defp create_repost(%User{} = user, %Post{} = original_post, _opts) do
    repost_attrs = %{
      content: " ",  # Single space to satisfy NOT NULL constraint
      user_id: user.id,
      shared_post_id: original_post.id,
      visibility: "public",
      metadata: %{share_type: "repost"},
      published_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }

    result = create_post(repost_attrs)
    
    case result do
      {:ok, _repost} ->
        increment_shares_count(original_post)
        result
      error -> error
    end
  end

  defp create_quote_share(%User{} = user, %Post{} = original_post, %{quote_content: content}) do
    quote_attrs = %{
      content: content,
      user_id: user.id,
      shared_post_id: original_post.id,
      visibility: "public",
      metadata: %{share_type: "quote"}
    }

    result = create_post(quote_attrs)
    
    case result do
      {:ok, _quote_post} ->
        increment_shares_count(original_post)
        result
      error -> error
    end
  end

  defp share_via_dm(%User{} = _user, %Post{} = post, %{recipient_id: _recipient_id}) do
    # This will integrate with your existing messaging system
    _message_content = "Check out this post: #{generate_share_link(post)}"
    
    # You can implement this based on your existing message system
    # For now, return a simple success
    {:ok, %{type: :direct_message, link: generate_share_link(post)}}
  end

  defp generate_share_link(%Post{} = post) do
    # Generate a shareable URL for the post
    base_url = Application.get_env(:cream_social, :base_url, "http://localhost:4001")
    "#{base_url}/stream/#{post.id}"
  end

  defp increment_shares_count(%Post{} = post) do
    from(p in Post, where: p.id == ^post.id)
    |> Repo.update_all(inc: [shares_count: 1])
  end

  def get_shared_post(%Post{shared_post_id: nil}), do: nil
  def get_shared_post(%Post{shared_post_id: shared_post_id}) when is_integer(shared_post_id) do
    get_post(shared_post_id)
  end
end