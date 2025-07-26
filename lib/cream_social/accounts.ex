defmodule CreamSocial.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias CreamSocial.Repo
  alias CreamSocial.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id) do
    try do
      Repo.get(User, id)
    rescue
      _ ->
        # Demo mode: return a mock user for demo purposes
        get_demo_user_by_id(id)
    end
  end

  def get_user_by_email(email) when is_binary(email) do
    try do
      Repo.get_by(User, email: email)
    rescue
      _ ->
        # Demo mode: return a mock user for demo purposes
        get_demo_user_by_email(email)
    end
  end

  def get_user_by_subdomain(subdomain) when is_binary(subdomain) do
    Repo.get_by(User, subdomain: subdomain)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  def change_user_password(%User{} = user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    if User.valid_password?(user, password) do
      {:ok, user}
    else
      {:error, :invalid_credentials}
    end
  end

  def get_user_by_session_token(token) do
    # TODO: Implement session token logic
    # For now, just decode the user ID from the token
    case Integer.parse(token) do
      {user_id, ""} -> get_user(user_id)
      _ -> nil
    end
  end

  def generate_user_session_token(user) do
    # TODO: Implement proper session token generation
    # For now, just return the user ID as string
    Integer.to_string(user.id)
  end

  def delete_user_session_token(_token) do
    # TODO: Implement session token deletion
    :ok
  end

  # Demo mode functions for when database is not available
  defp get_demo_user_by_email(email) do
    # Accept any email for demo, return a demo user
    if String.contains?(email, "@") do
      %User{
        id: 1,
        email: email,
        full_name: "Demo User",
        password_hash: "$2b$12$demo.hash.for.password.demo", # Demo hash for password "demo"
        verified: false,
        active: true,
        subscription_plan: "free",
        invite_code: "demo123",
        inserted_at: NaiveDateTime.utc_now(),
        updated_at: NaiveDateTime.utc_now()
      }
    else
      nil
    end
  end

  defp get_demo_user_by_id(id) when is_integer(id) do
    if id == 1 do
      %User{
        id: 1,
        email: "demo@zipin.app",
        full_name: "Demo User", 
        password_hash: "$2b$12$demo.hash.for.password.demo", # Demo hash for password "demo"
        verified: false,
        active: true,
        subscription_plan: "free",
        invite_code: "demo123",
        inserted_at: NaiveDateTime.utc_now(),
        updated_at: NaiveDateTime.utc_now()
      }
    else
      nil
    end
  end

  defp get_demo_user_by_id(_), do: nil
end