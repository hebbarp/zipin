defmodule CreamSocialWeb.BookmarksLive.Index do
  use CreamSocialWeb, :live_view
  alias CreamSocial.{Content, Accounts}

  @impl true
  def mount(_params, session, socket) do
    current_user = get_current_user(session)
    bookmarks = Content.list_user_bookmarks(current_user)

    socket = 
      socket
      |> assign(:current_user, current_user)
      |> assign(:bookmarks, bookmarks)
      |> assign(:page_title, "Bookmarks")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Your Bookmarks")
  end

  @impl true
  def handle_event("remove_bookmark", %{"post_id" => post_id}, socket) do
    current_user = socket.assigns.current_user
    post = Content.get_post!(post_id)

    case Content.toggle_bookmark(current_user, post) do
      {:ok, _} ->
        bookmarks = Content.list_user_bookmarks(current_user)
        socket = 
          socket
          |> assign(:bookmarks, bookmarks)
          |> put_flash(:info, "Bookmark removed")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to remove bookmark")}
    end
  end

  defp get_current_user(session) do
    user_token = Map.get(session, "user_token")
    user_token && Accounts.get_user_by_session_token(user_token)
  end
end