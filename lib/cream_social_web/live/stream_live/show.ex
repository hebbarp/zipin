defmodule CreamSocialWeb.StreamLive.Show do
  use CreamSocialWeb, :live_view
  import CreamSocialWeb.LiveHelpers
  alias CreamSocial.{Content, Accounts}
  alias CreamSocial.Content.Post

  @impl true
  def mount(%{"id" => id}, session, socket) do
    current_user = get_current_user(session)
    post = Content.get_post_with_replies!(id)
    
    socket = 
      socket
      |> assign(:current_user, current_user)
      |> assign(:post, post)
      |> assign(:page_title, "Post by #{post.user.full_name}")
      |> assign(:reply_form, to_form(Content.change_post(%Post{}), as: :reply))
      |> assign(:reply_to_post_id, nil)
      |> allow_upload(:reply_media, 
          accept: ~w(.jpg .jpeg .png .gif .mp4 .mov .avi),
          max_entries: 4,
          max_file_size: 10_000_000)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  @impl true
  def handle_event("toggle_reply", %{"post_id" => post_id}, socket) do
    current_reply_id = socket.assigns.reply_to_post_id
    post_id_int = String.to_integer(post_id)
    
    new_reply_id = if current_reply_id == post_id_int, do: nil, else: post_id_int
    
    socket = 
      socket
      |> assign(:reply_to_post_id, new_reply_id)
      |> assign(:reply_form, to_form(Content.change_post(%Post{}), as: :reply))
    
    {:noreply, socket}
  end

  def handle_event("create_reply", %{"reply" => reply_params, "post_id" => post_id}, socket) do
    current_user = socket.assigns.current_user
    
    # Handle file uploads for reply
    uploaded_files = 
      consume_uploaded_entries(socket, :reply_media, fn %{path: path}, entry ->
        dest = Path.join(["priv", "static", "uploads", "#{entry.uuid}.#{get_file_extension(entry.client_name)}"])
        
        # Ensure uploads directory exists
        File.mkdir_p!(Path.dirname(dest))
        
        # Copy uploaded file to destination
        File.cp!(path, dest)
        
        # Return the web path
        {:ok, "/uploads/#{entry.uuid}.#{get_file_extension(entry.client_name)}"}
      end)
    
    reply_params = 
      reply_params
      |> Map.put("user_id", current_user.id)
      |> Map.put("parent_id", String.to_integer(post_id))
      |> Map.put("media_paths", uploaded_files)

    case Content.create_post(reply_params) do
      {:ok, _reply} ->
        # Reload the post with updated replies
        post = Content.get_post_with_replies!(socket.assigns.post.id)
        
        socket = 
          socket
          |> put_flash(:info, "Reply posted successfully!")
          |> assign(:post, post)
          |> assign(:reply_to_post_id, nil)
          |> assign(:reply_form, to_form(Content.change_post(%Post{}), as: :reply))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :reply_form, to_form(changeset, as: :reply))}
    end
  end

  def handle_event("validate_reply", %{"reply" => _reply_params}, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-reply-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :reply_media, ref)}
  end

  def handle_event("toggle_like", %{"post_id" => post_id}, socket) do
    current_user = socket.assigns.current_user
    post = Content.get_post!(post_id)

    case Content.toggle_like(current_user, post) do
      {:ok, _} ->
        # Reload the post with updated likes
        updated_post = Content.get_post_with_replies!(socket.assigns.post.id)
        socket = assign(socket, :post, updated_post)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to like post")}
    end
  end

  def handle_event("toggle_bookmark", %{"post_id" => post_id}, socket) do
    current_user = socket.assigns.current_user
    post = Content.get_post!(post_id)

    case Content.toggle_bookmark(current_user, post) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Bookmark updated")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to bookmark post")}
    end
  end

  def handle_event("copy_link", %{"post_id" => post_id}, socket) do
    post = Content.get_post!(String.to_integer(post_id))
    link = Content.share_post(nil, post, :copy_link)
    
    socket = 
      socket
      |> put_flash(:info, "Link copied to clipboard!")
      |> push_event("copy-to-clipboard", %{text: link})
    
    {:noreply, socket}
  end

  def handle_event("toggle_share", %{"post_id" => post_id}, socket) do
    {:noreply, put_flash(socket, :info, "Sharing functionality not available on detail page")}
  end

  def handle_event("set_share_type", %{"type" => "repost", "post_id" => post_id}, socket) do
    current_user = socket.assigns.current_user
    post = Content.get_post!(String.to_integer(post_id))
    
    case Content.share_post(current_user, post, :repost) do
      {:ok, _result} ->
        {:noreply, put_flash(socket, :info, "Post shared to your timeline!")}
      
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Unable to share post: #{reason}")}
    end
  end

  def handle_event("set_share_type", %{"type" => share_type, "post_id" => post_id}, socket) do
    {:noreply, put_flash(socket, :info, "Quote sharing not available on detail page")}
  end

  def handle_event("share_post", params, socket) do
    {:noreply, put_flash(socket, :info, "Share functionality not available on detail page")}
  end

  defp get_current_user(session) do
    user_token = Map.get(session, "user_token")
    user_token && Accounts.get_user_by_session_token(user_token)
  end

  defp get_file_extension(filename) do
    filename
    |> Path.extname()
    |> String.trim_leading(".")
    |> String.downcase()
  end

  def reply_thread(assigns) do
    assigns = assign_new(assigns, :depth, fn -> 0 end)
    
    # Define thread colors that cycle through different hues
    thread_colors = [
      "border-l-blue-400",      # depth 0
      "border-l-purple-400",    # depth 1  
      "border-l-pink-400",      # depth 2
      "border-l-red-400",       # depth 3
      "border-l-orange-400",    # depth 4
      "border-l-yellow-400",    # depth 5
      "border-l-green-400",     # depth 6
      "border-l-teal-400",      # depth 7
      "border-l-cyan-400"       # depth 8
    ]
    
    # Get color for current depth, cycling through colors
    color_class = Enum.at(thread_colors, rem(assigns.depth, length(thread_colors)))
    
    assigns = assign(assigns, :color_class, color_class)
    
    ~H"""
    <div class="reply-container">
      <div class="bg-white rounded-lg shadow mb-4 p-4">
        <div class="flex items-center space-x-3 mb-3">
          <div class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center">
            <%= if @reply.user.profile_pic do %>
              <img src={@reply.user.profile_pic} alt="" class="w-8 h-8 rounded-full object-cover">
            <% else %>
              <span class="text-gray-600 text-sm"><%= String.first(@reply.user.full_name) %></span>
            <% end %>
          </div>
          <div>
            <h4 class="text-sm font-semibold"><%= @reply.user.full_name %></h4>
            <p class="text-xs text-gray-500"><%= time_ago(@reply.published_at) %></p>
          </div>
        </div>
        <p class="text-sm text-gray-900 mb-3"><%= @reply.content %></p>
        
        <%= if @reply.media_paths && length(@reply.media_paths) > 0 do %>
          <div class="mt-4 grid grid-cols-2 gap-2">
            <%= for media_path <- @reply.media_paths do %>
              <%= if String.ends_with?(media_path, [".mp4", ".mov", ".avi", ".webm"]) do %>
                <video controls class="rounded-lg w-full h-32">
                  <source src={media_path} type="video/mp4">
                </video>
              <% else %>
                <img src={media_path} alt="Reply media" class="rounded-lg object-cover w-full h-32">
              <% end %>
            <% end %>
          </div>
        <% end %>
        
        <!-- Reply Actions -->
        <div class="flex items-center justify-between mt-3 pt-3 border-t border-gray-100">
          <div class="flex items-center space-x-4">
            <button
              phx-click="toggle_like"
              phx-value-post_id={@reply.id}
              class="flex items-center space-x-1 text-gray-500 hover:text-red-500 transition-colors text-xs"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
              <span><%= @reply.likes_count %></span>
            </button>

            <button
              phx-click="toggle_reply"
              phx-value-post_id={@reply.id}
              class="flex items-center space-x-1 text-gray-500 hover:text-blue-500 transition-colors text-xs"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-3.582 8-8 8a8.001 8.001 0 01-7.227-4.612 6.729 6.729 0 000-6.776A8.001 8.001 0 0121 12z" />
              </svg>
              <span><%= CreamSocial.Content.count_all_replies(@reply.replies) %></span>
            </button>

            <button class="flex items-center space-x-1 text-gray-500 hover:text-green-500 transition-colors text-xs">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z" />
              </svg>
              <span><%= @reply.shares_count %></span>
            </button>
          </div>

          <button
            phx-click="toggle_bookmark"
            phx-value-post_id={@reply.id}
            class="text-gray-500 hover:text-yellow-500 transition-colors"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
            </svg>
          </button>
        </div>
      </div>
      
      <!-- Reply Form (conditional) -->
      <%= if @reply_to_post_id == @reply.id do %>
        <div class="mt-4 p-4 bg-gray-50 rounded-lg">
          <.form for={@reply_form} phx-submit="create_reply" phx-change="validate_reply" phx-value-post_id={@reply.id} multipart class="space-y-3">
            <div>
              <.input
                field={@reply_form[:content]}
                type="textarea"
                placeholder="Write a reply..."
                rows="2"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
              />
            </div>

            <div class="flex justify-between items-center">
              <button
                type="button"
                phx-click="toggle_reply"
                phx-value-post_id={@reply.id}
                class="text-sm text-gray-500 hover:text-gray-700"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Reply
              </button>
            </div>
          </.form>
        </div>
      <% end %>
      
      <%= if @reply.replies && length(@reply.replies) > 0 do %>
        <div class={"ml-8 border-l-4 #{@color_class} pl-4"}>
          <%= for nested_reply <- @reply.replies do %>
            <.reply_thread 
              reply={nested_reply}
              current_user={@current_user}
              reply_to_post_id={@reply_to_post_id}
              reply_form={@reply_form}
              uploads={@uploads}
              depth={@depth + 1}
            />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

end