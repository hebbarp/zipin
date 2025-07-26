defmodule CreamSocial.Social do
  @moduledoc """
  The Social context for handling follows, friendships, and social interactions.
  """

  import Ecto.Query, warn: false
  alias CreamSocial.Repo
  alias CreamSocial.Social.Follow
  alias CreamSocial.Accounts.User

  @doc """
  Creates a follow relationship between two users.
  """
  def follow_user(follower_id, followed_id) do
    %Follow{}
    |> Follow.changeset(%{
      follower_id: follower_id,
      followed_id: followed_id,
      status: "active"
    })
    |> Repo.insert()
  end

  @doc """
  Removes a follow relationship between two users.
  """
  def unfollow_user(follower_id, followed_id) do
    case get_follow(follower_id, followed_id) do
      nil -> {:error, :not_found}
      follow -> Repo.delete(follow)
    end
  end

  @doc """
  Checks if user1 is following user2.
  """
  def following?(follower_id, followed_id) do
    from(f in Follow,
      where: f.follower_id == ^follower_id and 
             f.followed_id == ^followed_id and 
             f.status == "active"
    )
    |> Repo.exists?()
  end

  @doc """
  Gets a follow relationship between two users.
  """
  def get_follow(follower_id, followed_id) do
    from(f in Follow,
      where: f.follower_id == ^follower_id and f.followed_id == ^followed_id
    )
    |> Repo.one()
  end

  @doc """
  Gets the number of users following the given user.
  """
  def get_followers_count(user_id) do
    from(f in Follow,
      where: f.followed_id == ^user_id and f.status == "active"
    )
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the number of users the given user is following.
  """
  def get_following_count(user_id) do
    from(f in Follow,
      where: f.follower_id == ^user_id and f.status == "active"
    )
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets users who are following the given user.
  """
  def get_followers(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(u in User,
      join: f in Follow,
      on: f.follower_id == u.id,
      where: f.followed_id == ^user_id and f.status == "active",
      order_by: [desc: f.inserted_at],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
  end

  @doc """
  Gets users that the given user is following.
  """
  def get_following(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(u in User,
      join: f in Follow,
      on: f.followed_id == u.id,
      where: f.follower_id == ^user_id and f.status == "active",
      order_by: [desc: f.inserted_at],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
  end

  @doc """
  Toggles follow/unfollow for a user.
  """
  def toggle_follow(follower_id, followed_id) do
    if following?(follower_id, followed_id) do
      unfollow_user(follower_id, followed_id)
    else
      follow_user(follower_id, followed_id)
    end
  end

  @doc """
  Gets suggested users to follow (excludes already followed users).
  """
  def get_suggested_users(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    followed_user_ids = 
      from(f in Follow,
        where: f.follower_id == ^user_id and f.status == "active",
        select: f.followed_id
      )

    from(u in User,
      where: u.id != ^user_id and u.id not in subquery(followed_user_ids),
      where: u.active == true,
      order_by: [desc: u.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end
end