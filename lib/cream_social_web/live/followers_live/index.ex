defmodule CreamSocialWeb.FollowersLive.Index do
  use CreamSocialWeb, :live_view
  alias CreamSocial.{Accounts, Social}

  @impl true
  def mount(%{"user_id" => user_id}, session, socket) do
    current_user = get_current_user(session)
    target_user = Accounts.get_user!(user_id)
    
    socket = 
      socket
      |> assign(:current_user, current_user)
      |> assign(:target_user, target_user)
      |> assign(:followers, Social.get_followers(target_user.id))
      |> assign(:followers_count, Social.get_followers_count(target_user.id))
      |> assign(:page_title, "#{target_user.full_name}'s Followers")

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_follow", %{"user_id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    current_user_id = socket.assigns.current_user.id

    case Social.toggle_follow(current_user_id, user_id) do
      {:ok, _follow} ->
        socket = 
          socket
          |> put_flash(:info, "Successfully updated follow status")
          |> assign(:followers, Social.get_followers(socket.assigns.target_user.id))
        {:noreply, socket}
      
      {:error, _changeset} ->
        socket = put_flash(socket, :error, "Unable to update follow status")
        {:noreply, socket}
    end
  end

  defp get_current_user(session) do
    user_token = Map.get(session, "user_token")
    user_token && Accounts.get_user_by_session_token(user_token)
  end

  defp is_following?(current_user_id, target_user_id) do
    Social.following?(current_user_id, target_user_id)
  end
end