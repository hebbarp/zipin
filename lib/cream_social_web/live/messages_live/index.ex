defmodule CreamSocialWeb.MessagesLive.Index do
  use CreamSocialWeb, :live_view
  import CreamSocialWeb.LiveHelpers
  alias CreamSocial.{Messaging, Accounts}

  @impl true
  def mount(_params, session, socket) do
    current_user = get_current_user(session)
    conversations = Messaging.list_conversations(current_user)

    # Subscribe to real-time message updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CreamSocial.PubSub, "messages:#{current_user.id}")
    end

    socket = 
      socket
      |> assign(:current_user, current_user)
      |> assign(:conversations, conversations)
      |> assign(:selected_user, nil)
      |> assign(:messages, [])
      |> assign(:new_message, "")
      |> assign(:unread_count, Messaging.get_unread_count(current_user))
      |> assign(:page_title, "Messages")

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"user_id" => user_id}, _url, socket) do
    current_user = socket.assigns.current_user
    selected_user = Accounts.get_user!(user_id)
    messages = Messaging.list_messages(current_user, selected_user)

    # Mark messages as read
    Messaging.mark_messages_as_read(current_user, selected_user)

    # Refresh conversations to include this user if not already present
    conversations = Messaging.list_conversations(current_user)


    socket = 
      socket
      |> assign(:selected_user, selected_user)
      |> assign(:messages, messages)
      |> assign(:conversations, conversations)
      |> assign(:page_title, "Chat with #{selected_user.full_name}")

    {:noreply, socket}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => %{"content" => content}}, socket) do
    current_user = socket.assigns.current_user
    selected_user = socket.assigns.selected_user

    if String.trim(content) != "" do
      case Messaging.create_message(%{
        content: content,
        sender_id: current_user.id,
        recipient_id: selected_user.id
      }) do
        {:ok, _message} ->
          messages = Messaging.list_messages(current_user, selected_user)
          conversations = Messaging.list_conversations(current_user)
          socket = 
            socket
            |> assign(:messages, messages)
            |> assign(:conversations, conversations)
            |> assign(:new_message, "")

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to send message")}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_message", %{"message" => %{"content" => content}}, socket) do
    {:noreply, assign(socket, :new_message, content)}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    current_user = socket.assigns.current_user
    selected_user = socket.assigns.selected_user
    
    # Update conversations list
    conversations = Messaging.list_conversations(current_user)
    
    # If this message is for the currently selected conversation, update messages
    updated_messages = 
      if selected_user && 
         ((message.sender_id == current_user.id && message.recipient_id == selected_user.id) ||
          (message.sender_id == selected_user.id && message.recipient_id == current_user.id)) do
        
        # Mark as read if it's for the current conversation
        if message.recipient_id == current_user.id do
          Messaging.mark_messages_as_read(current_user, selected_user)
        end
        
        Messaging.list_messages(current_user, selected_user)
      else
        socket.assigns.messages
      end
    
    # Update unread count
    unread_count = Messaging.get_unread_count(current_user)
    
    # Show notification if it's a new message for current user from someone else
    socket = 
      if message.recipient_id == current_user.id && message.sender_id != current_user.id do
        put_flash(socket, :info, "New message from #{message.sender.full_name}")
      else
        socket
      end
    
    socket = 
      socket
      |> assign(:conversations, conversations)
      |> assign(:messages, updated_messages)
      |> assign(:unread_count, unread_count)
    
    {:noreply, socket}
  end

  defp get_current_user(session) do
    user_token = Map.get(session, "user_token")
    user_token && Accounts.get_user_by_session_token(user_token)
  end
end