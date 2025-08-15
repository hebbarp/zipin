defmodule CreamSocial.SocialFixtures do
  @moduledoc """
  Test fixtures for social context.
  """
  alias CreamSocial.{Accounts, Social}
  alias CreamSocial.Accounts.User

  def user_fixture(attrs \\ %{}) do
    default = %{
      email: unique_email(), 
      password: "Password123!", 
      full_name: "Test User"
    }
    {:ok, %User{} = user} =
      default
      |> Map.merge(attrs)
      |> Accounts.create_user()
    user
  end

  def follow_fixture(attrs \\ %{}) do
    follower = Map.get_lazy(attrs, :follower, fn -> user_fixture() end)
    followed = Map.get_lazy(attrs, :followed, fn -> user_fixture(%{email: unique_email()}) end)
    {:ok, follow} = Social.follow_user(follower.id, followed.id)
    follow
  end

  defp unique_email do
    "user_" <> Integer.to_string(System.unique_integer([:positive])) <> "@example.com"
  end
end
