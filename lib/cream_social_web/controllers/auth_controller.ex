defmodule CreamSocialWeb.AuthController do
  use CreamSocialWeb, :controller
  require Logger
  alias CreamSocial.Accounts
  
  plug :put_layout, html: :auth

  def login(conn, _params) do
    try do
      render(conn, :login)
    rescue
      e ->
        Logger.error("Error loading login page: #{inspect(e)}")
        text(conn, "Login page temporarily unavailable. Please try again later.")
    end
  end

  def register(conn, _params) do
    try do
      changeset = Accounts.change_user(%CreamSocial.Accounts.User{})
      render(conn, :register, changeset: changeset)
    rescue
      e ->
        Logger.error("Error loading registration page: #{inspect(e)}")
        changeset = Ecto.Changeset.change(%CreamSocial.Accounts.User{})
        render(conn, :register, changeset: changeset)
    end
  end

  def create_session(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        token = Accounts.generate_user_session_token(user)
        
        conn
        |> put_session(:user_token, token)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: ~p"/stream")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render(:login)
    end
  end

  def create_user(conn, %{"user" => user_params}) do
    try do
      case Accounts.create_user(user_params) do
        {:ok, user} ->
          token = Accounts.generate_user_session_token(user)
          
          conn
          |> put_session(:user_token, token)
          |> put_flash(:info, "Account created successfully!")
          |> redirect(to: ~p"/stream")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :register, changeset: changeset)
      end
    rescue
      e ->
        Logger.error("Error creating user: #{inspect(e)}")
        changeset = Ecto.Changeset.change(%CreamSocial.Accounts.User{})
        |> Ecto.Changeset.add_error(:email, "Something went wrong. Please try again.")
        
        conn
        |> put_flash(:error, "Unable to create account. Please try again.")
        |> render(:register, changeset: changeset)
    end
  end

  def delete_session(conn, _params) do
    token = get_session(conn, :user_token)
    if token, do: Accounts.delete_user_session_token(token)

    conn
    |> clear_session()
    |> put_flash(:info, "Logged out successfully")
    |> redirect(to: ~p"/")
  end
end