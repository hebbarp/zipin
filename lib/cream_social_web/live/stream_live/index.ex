defmodule CreamSocialWeb.StreamLive.Index do
  use CreamSocialWeb, :live_view
  import Ecto.Query
  require Logger
  alias CreamSocial.{Content, Accounts, Social, Repo, AIEnhancer, ContentGenerator}
  alias CreamSocial.Content.Post

  @impl true
  def mount(_params, session, socket) do
    try do
      current_user = get_current_user_safe(session)
      is_public = current_user == nil
      
      # Subscribe to post updates for real-time link previews (only if authenticated)
      if connected?(socket) && current_user do
        Phoenix.PubSub.subscribe(CreamSocial.PubSub, "post_updates")
      end
      
      # Safely get posts with error handling
      posts = try do
        if current_user do
          list_posts_with_follow_status(current_user.id)
        else
          list_public_posts()
        end
      rescue
        e ->
          Logger.error("Error loading posts: #{inspect(e)}")
          []
      end
      
      socket = 
        socket
        |> assign(:current_user, current_user)
        |> assign(:is_public, is_public)
        |> assign(:posts, posts)
        |> assign(:page_title, if(is_public, do: "ZipIn Bangalore - Discover Your City", else: "ZipIn - Your Local Social Hub"))
        |> assign_forms_if_authenticated(current_user)
        |> assign(:expanded_posts, MapSet.new())
        |> assign(:editing_post_id, nil)
        |> assign(:edit_form, nil)
        |> assign(:sharing_post_id, nil)
        |> assign(:typing_link_previews, [])
        |> assign(:ai_enhancing, nil)
        |> maybe_allow_uploads(current_user)

      {:ok, socket}
    rescue
      e ->
        Logger.error("Error mounting stream page: #{inspect(e)}")
        {:ok, assign(socket, :posts, [])}
    end
  end
  
  defp assign_forms_if_authenticated(socket, nil) do
    socket
    |> assign(:new_post_form, nil)
    |> assign(:reply_to_post_id, nil)
    |> assign(:reply_form, nil)
    |> assign(:share_form, nil)
    |> assign(:share_type, nil)
  end
  
  defp assign_forms_if_authenticated(socket, _current_user) do
    socket
    |> assign(:new_post_form, to_form(Content.change_post(%Post{}), as: :post))
    |> assign(:reply_to_post_id, nil)
    |> assign(:reply_form, to_form(Content.change_post(%Post{}), as: :reply))
    |> assign(:share_form, to_form(Content.change_post(%Post{}), as: :share))
    |> assign(:share_type, nil)
  end
  
  defp maybe_allow_uploads(socket, nil), do: socket
  defp maybe_allow_uploads(socket, _current_user) do
    socket
    |> allow_upload(:media, 
        accept: ~w(.jpg .jpeg .png .gif .mp4 .mov .avi),
        max_entries: 4,
        max_file_size: 10_000_000)
    |> allow_upload(:reply_media, 
        accept: ~w(.jpg .jpeg .png .gif .mp4 .mov .avi),
        max_entries: 4,
        max_file_size: 10_000_000)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "ZipIn - Your Local Social Hub")
  end
  
  defp apply_action(socket, :public, _params) do
    socket
    |> assign(:page_title, "ZipIn Bangalore - Discover Your City")
  end
  
  defp apply_action(socket, :places, _params) do
    socket
    |> assign(:page_title, "ZipIn - Discover Places")
  end
  
  defp apply_action(socket, :events, _params) do
    socket
    |> assign(:page_title, "ZipIn - Local Events")
  end

  # Authentication guard for actions
  defp require_auth(socket, action) do
    if socket.assigns.current_user do
      :ok
    else
      {:redirect, push_navigate(socket, to: ~p"/auth/login?redirect_to=#{action}")}
    end
  end

  @impl true
  def handle_event("create_post", %{"post" => post_params}, socket) do
    case require_auth(socket, "post") do
      :ok -> handle_create_post(socket, post_params)
      {:redirect, socket} -> {:noreply, socket}
    end
  end

  def handle_event("validate", %{"post" => post_params}, socket) do
    # Extract and preview links in real-time as user types
    if content = post_params["content"] do
      urls = CreamSocial.Content.LinkExtractor.extract_links_from_text(content)
      
      # Start link extraction in background for preview
      Enum.each(urls, fn url ->
        Task.start(fn ->
          case CreamSocial.Content.LinkExtractor.extract_and_cache(url) do
            {:ok, preview} ->
              # Send preview to LiveView for display
              send(self(), {:link_preview_ready, url, preview})
            _error ->
              :ok
          end
        end)
      end)

      # Update viral score predictor with new content
      send_update(CreamSocialWeb.StreamLive.ViralScoreComponent,
        id: "viral-predictor",
        content: content)
    end
    
    {:noreply, socket}
  end

  def handle_event("validate_reply", %{"reply" => _reply_params}, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :media, ref)}
  end

  def handle_event("cancel-reply-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :reply_media, ref)}
  end

  def handle_event("toggle_like", %{"post_id" => post_id}, socket) do
    case require_auth(socket, "like") do
      :ok -> handle_toggle_like(socket, post_id)
      {:redirect, socket} -> {:noreply, socket}
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

  def handle_event("test_reply", %{"post_id" => post_id}, socket) do
    socket = put_flash(socket, :info, "Reply button clicked for post #{post_id}!")
    {:noreply, socket}
  end

  def handle_event("toggle_expand", %{"post_id" => post_id}, socket) do
    post_id_int = String.to_integer(post_id)
    expanded_posts = socket.assigns.expanded_posts
    
    new_expanded_posts = 
      if MapSet.member?(expanded_posts, post_id_int) do
        MapSet.delete(expanded_posts, post_id_int)
      else
        MapSet.put(expanded_posts, post_id_int)
      end
    
    {:noreply, assign(socket, :expanded_posts, new_expanded_posts)}
  end

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
        socket = 
          socket
          |> put_flash(:info, "Reply posted successfully!")
          |> assign(:posts, list_posts_with_follow_status(socket.assigns.current_user.id))
          |> assign(:reply_to_post_id, nil)
          |> assign(:reply_form, to_form(Content.change_post(%Post{}), as: :reply))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :reply_form, to_form(changeset, as: :reply))}
    end
  end

  def handle_event("edit_post", %{"post_id" => post_id}, socket) do
    post_id_int = String.to_integer(post_id)
    post = Content.get_post!(post_id_int)
    
    # Only allow editing own posts
    if post.user_id == socket.assigns.current_user.id do
      socket = 
        socket
        |> assign(:editing_post_id, post_id_int)
        |> assign(:edit_form, to_form(Content.change_post(post), as: :edit_post))
      
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "You can only edit your own posts")}
    end
  end

  def handle_event("update_post", %{"edit_post" => post_params, "post_id" => post_id}, socket) do
    current_user = socket.assigns.current_user
    post = Content.get_post!(String.to_integer(post_id))
    
    # Only allow updating own posts
    if post.user_id == current_user.id do
      # Handle file uploads for edit
      uploaded_files = 
        consume_uploaded_entries(socket, :media, fn %{path: path}, entry ->
          dest = Path.join(["priv", "static", "uploads", "#{entry.uuid}.#{get_file_extension(entry.client_name)}"])
          
          # Ensure uploads directory exists
          File.mkdir_p!(Path.dirname(dest))
          
          # Copy uploaded file to destination
          File.cp!(path, dest)
          
          # Return the web path
          {:ok, "/uploads/#{entry.uuid}.#{get_file_extension(entry.client_name)}"}
        end)
      
      # Add new uploaded files to existing media (or replace if checkbox checked)
      post_params = 
        if length(uploaded_files) > 0 do
          Map.put(post_params, "media_paths", uploaded_files)
        else
          post_params
        end

      case Content.update_post(post, post_params) do
        {:ok, _updated_post} ->
          socket = 
            socket
            |> put_flash(:info, "Post updated successfully!")
            |> assign(:posts, list_posts_with_follow_status(socket.assigns.current_user.id))
            |> assign(:editing_post_id, nil)
            |> assign(:edit_form, nil)

          {:noreply, socket}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :edit_form, to_form(changeset, as: :edit_post))}
      end
    else
      {:noreply, put_flash(socket, :error, "You can only edit your own posts")}
    end
  end

  def handle_event("cancel_edit", _params, socket) do
    socket = 
      socket
      |> assign(:editing_post_id, nil)
      |> assign(:edit_form, nil)
    
    {:noreply, socket}
  end

  def handle_event("delete_post", %{"post_id" => post_id}, socket) do
    current_user = socket.assigns.current_user
    post = Content.get_post!(String.to_integer(post_id))
    
    # Only allow deleting own posts
    if post.user_id == current_user.id do
      case Content.delete_post(post) do
        {:ok, _deleted_post} ->
          # Force a fresh query and update
          fresh_posts = list_posts_with_follow_status(current_user.id)
          
          socket = 
            socket
            |> put_flash(:info, "Post deleted successfully!")
            |> assign(:posts, fresh_posts)
            |> push_event("post-deleted", %{post_id: post_id})

          {:noreply, socket}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Unable to delete post")}
      end
    else
      {:noreply, put_flash(socket, :error, "You can only delete your own posts")}
    end
  end

  def handle_event("toggle_share", %{"post_id" => post_id}, socket) do
    current_sharing_id = socket.assigns.sharing_post_id
    post_id_int = String.to_integer(post_id)
    
    new_sharing_id = if current_sharing_id == post_id_int, do: nil, else: post_id_int
    
    socket = 
      socket
      |> assign(:sharing_post_id, new_sharing_id)
      |> assign(:share_form, to_form(Content.change_post(%Post{}), as: :share))
      |> assign(:share_type, nil)
    
    {:noreply, socket}
  end

  def handle_event("enhance_message", %{"post_id" => post_id, "content" => content}, socket) do
    post_id_int = String.to_integer(post_id)
    current_content = String.trim(content)
    
    if current_content == "" do
      socket = put_flash(socket, :error, "Please enter some text to enhance")
      {:noreply, socket}
    else
      # Set loading state
      socket = assign(socket, :ai_enhancing, post_id_int)
      
      # Start async AI enhancement
      send(self(), {:enhance_message_async, post_id_int, current_content})
      {:noreply, socket}
    end
  end

  def handle_event("enhance_new_post", %{"content" => content}, socket) do
    current_content = String.trim(content)
    
    if current_content == "" do
      socket = put_flash(socket, :error, "Please enter some text to enhance")
      {:noreply, socket}
    else
      # Set loading state
      socket = assign(socket, :ai_enhancing, :new_post)
      
      # Start async AI enhancement
      send(self(), {:enhance_new_post_async, current_content})
      {:noreply, socket}
    end
  end

  def handle_event("enhance_reply", %{"post_id" => post_id, "content" => content}, socket) do
    post_id_int = String.to_integer(post_id)
    current_content = String.trim(content)
    
    if current_content == "" do
      socket = put_flash(socket, :error, "Please enter some text to enhance")
      {:noreply, socket}
    else
      # Set loading state
      socket = assign(socket, :ai_enhancing, "reply_#{post_id_int}")
      
      # Start async AI enhancement
      send(self(), {:enhance_reply_async, post_id_int, current_content})
      {:noreply, socket}
    end
  end

  def handle_event("set_share_type", %{"type" => "repost", "post_id" => post_id}, socket) do
    try do
      # For repost, immediately share without form
      current_user = socket.assigns.current_user
      post = Content.get_post!(String.to_integer(post_id))
      
      case Content.share_post(current_user, post, :repost) do
        {:ok, _result} ->
          # Refresh posts list to show the new repost immediately
          socket = 
            socket
            |> put_flash(:info, "Post shared to your timeline!")
            |> assign(:posts, list_posts_with_follow_status(current_user.id))
          {:noreply, socket}
        
        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Unable to share post: #{inspect(reason)}")}
      end
    rescue
      error ->
        IO.puts("=== REPOST ERROR ===")
        IO.inspect(error)
        IO.inspect(__STACKTRACE__)
        {:noreply, put_flash(socket, :error, "Repost failed: #{inspect(error)}")}
    end
  end

  def handle_event("set_share_type", %{"type" => share_type, "post_id" => post_id}, socket) do
    socket = 
      socket
      |> assign(:share_type, share_type)
      |> assign(:sharing_post_id, String.to_integer(post_id))
    
    {:noreply, socket}
  end

  def handle_event("share_post", params, socket) do
    current_user = socket.assigns.current_user
    post_id = String.to_integer(params["post_id"])
    post = Content.get_post!(post_id)
    share_type = String.to_atom(socket.assigns.share_type)
    
    opts = case share_type do
      :quote -> %{quote_content: params["share"]["content"]}
      :direct_message -> %{recipient_id: params["recipient_id"]}
      _ -> %{}
    end

    case Content.share_post(current_user, post, share_type, opts) do
      {:ok, result} ->
        socket = 
          socket
          |> handle_share_success(result, share_type)
          |> assign(:sharing_post_id, nil)
          |> assign(:share_type, nil)
          |> assign(:share_form, to_form(Content.change_post(%Post{}), as: :share))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :share_form, to_form(changeset, as: :share))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Unable to share post: #{reason}")}
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

  def handle_event("toggle_follow", %{"user_id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    current_user_id = socket.assigns.current_user.id

    case Social.toggle_follow(current_user_id, user_id) do
      {:ok, _follow} ->
        socket = 
          socket
          |> put_flash(:info, "Successfully updated follow status")
          |> assign(:posts, list_posts_with_follow_status(current_user_id))
        {:noreply, socket}
      
      {:error, _changeset} ->
        socket = put_flash(socket, :error, "Unable to update follow status")
        {:noreply, socket}
    end
  end

  defp handle_create_post(socket, post_params) do
    current_user = socket.assigns.current_user
    
    # Handle file uploads
    uploaded_files = 
      consume_uploaded_entries(socket, :media, fn %{path: path}, entry ->
        dest = Path.join(["priv", "static", "uploads", "#{entry.uuid}.#{get_file_extension(entry.client_name)}"])
        
        # Ensure uploads directory exists
        File.mkdir_p!(Path.dirname(dest))
        
        # Copy uploaded file to destination
        File.cp!(path, dest)
        
        # Return the web path
        {:ok, "/uploads/#{entry.uuid}.#{get_file_extension(entry.client_name)}"}
      end)

    post_params = 
      post_params
      |> Map.put("user_id", current_user.id)
      |> Map.put("media_paths", uploaded_files)

    case Content.create_post(post_params) do
      {:ok, _post} ->
        # Create a fresh form with empty changeset
        fresh_changeset = Content.change_post(%Post{})
        
        socket = 
          socket
          |> put_flash(:info, "Post created successfully!")
          |> assign(:posts, list_posts_with_follow_status(socket.assigns.current_user.id))
          |> assign(:new_post_form, to_form(fresh_changeset, as: :post))
          |> push_event("clear-form", %{})

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :new_post_form, to_form(changeset, as: :post))}
    end
  end

  defp handle_toggle_like(socket, post_id) do
    current_user = socket.assigns.current_user
    post = Content.get_post!(post_id)

    case Content.toggle_like(current_user, post) do
      {:ok, _} ->
        socket = assign(socket, :posts, list_posts_with_follow_status(current_user.id))
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to like post")}
    end
  end

  defp handle_share_success(socket, _result, share_type) do
    current_user_id = socket.assigns.current_user.id
    case share_type do
      :repost ->
        socket
        |> put_flash(:info, "Post shared to your timeline!")
        |> assign(:posts, list_posts_with_follow_status(current_user_id))
      
      :quote ->
        socket
        |> put_flash(:info, "Quote shared to your timeline!")
        |> assign(:posts, list_posts_with_follow_status(current_user_id))
      
      :direct_message ->
        put_flash(socket, :info, "Post shared via direct message!")
      
      :copy_link ->
        put_flash(socket, :info, "Link copied to clipboard!")
    end
  end

  @impl true
  def handle_info({:post_updated, post_id}, socket) do
    # Find and update the specific post in the list
    updated_posts = Enum.map(socket.assigns.posts, fn p ->
      if p.id == post_id do
        # Refetch the single post that was updated
        Content.get_post!(post_id)
        |> Map.put(:follow_info, p.follow_info) # Preserve existing follow info
      else
        p
      end
    end)
    
    {:noreply, assign(socket, :posts, updated_posts)}
  end

  @impl true
  def handle_info({:link_preview_added, post_id, _link_preview}, socket) do
    Logger.info("Ignoring :link_preview_added event for post #{post_id} to prevent flickering.")
    {:noreply, socket}
  end

  @impl true
  def handle_info({:share_content, content}, socket) do
    # Handle shared content from components (places, events, etc.)
    socket = 
      socket
      |> assign(:new_post_form, to_form(Content.change_post(%Post{content: content}), as: :post))
      |> put_flash(:info, "Content added to post form")
    
    {:noreply, socket}
  end

  def handle_info({:link_preview_ready, url, preview}, socket) do
    # Add to typing previews for real-time display
    current_previews = socket.assigns.typing_link_previews
    new_previews = [%{url: url, preview: preview} | current_previews]
    socket = assign(socket, :typing_link_previews, new_previews)
    {:noreply, socket}
  end

  def handle_info({:enhance_message_async, post_id, content}, socket) do
    # Perform AI enhancement in the background
    current_user = socket.assigns.current_user
    case AIEnhancer.enhance_message(content, current_user) do
      {:ok, enhanced_content} ->
        # Update the form with enhanced content
        enhanced_changeset = Content.change_post(%Post{content: enhanced_content})
        share_form = to_form(enhanced_changeset, as: :share)
        
        socket = 
          socket
          |> assign(:share_form, share_form)
          |> assign(:ai_enhancing, nil)
          |> put_flash(:info, "✨ Message enhanced! Your text has been polished with AI.")
        
        {:noreply, socket}
      
      {:error, reason} ->
        socket = 
          socket
          |> assign(:ai_enhancing, nil)
          |> put_flash(:error, "AI enhancement failed: #{reason}")
        
        {:noreply, socket}
    end
  end

  def handle_info({:enhance_new_post_async, content}, socket) do
    # Perform AI enhancement in the background
    try do
      current_user = socket.assigns.current_user
      case AIEnhancer.enhance_message(content, current_user) do
        {:ok, enhanced_content} ->
          # Update the form with enhanced content
          enhanced_changeset = Content.change_post(%Post{content: enhanced_content})
          new_post_form = to_form(enhanced_changeset, as: :post)
          
          socket = 
            socket
            |> assign(:new_post_form, new_post_form)
            |> assign(:ai_enhancing, nil)
            |> put_flash(:info, "✨ Message enhanced! Your text has been polished with AI.")
          
          {:noreply, socket}
        
        {:error, reason} ->
          socket = 
            socket
            |> assign(:ai_enhancing, nil)
            |> put_flash(:error, "AI enhancement failed: #{reason}")
          
          {:noreply, socket}
      end
    rescue
      error ->
        Logger.error("AI Enhancement crashed: #{inspect(error)}")
        socket = 
          socket
          |> assign(:ai_enhancing, nil)
          |> put_flash(:error, "AI enhancement encountered an error")
        
        {:noreply, socket}
    end
  end

  def handle_info({:enhance_reply_async, post_id, content}, socket) do
    # Perform AI enhancement in the background
    current_user = socket.assigns.current_user
    case AIEnhancer.enhance_message(content, current_user) do
      {:ok, enhanced_content} ->
        # Update the form with enhanced content
        enhanced_changeset = Content.change_post(%Post{content: enhanced_content})
        reply_form = to_form(enhanced_changeset, as: :reply)
        
        socket = 
          socket
          |> assign(:reply_form, reply_form)
          |> assign(:ai_enhancing, nil)
          |> put_flash(:info, "✨ Reply enhanced! Your text has been polished with AI.")
        
        {:noreply, socket}
      
      {:error, reason} ->
        socket = 
          socket
          |> assign(:ai_enhancing, nil)
          |> put_flash(:error, "AI enhancement failed: #{reason}")
        
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:generate_post_from_template, template_key, component_id}, socket) do
    try do
      current_user = socket.assigns.current_user
      
      # Generate content using the template
      case ContentGenerator.generate_post(template_key, %{}, current_user) do
        {:ok, generated_content} ->
          send(self(), {:ai_generated_content, generated_content})
          send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
            id: component_id, 
            action: :generation_complete)
        
        {:error, reason} ->
          send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
            id: component_id, 
            action: {:generation_failed, reason})
      end
    rescue
      error ->
        Logger.error("AI Post Generation crashed: #{inspect(error)}")
        send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
          id: component_id, 
          action: {:generation_failed, "Post generation encountered an error"})
    end
    
    {:noreply, socket}
  end

  def handle_info({:generate_post_from_topic, topic, component_id}, socket) do
    try do
      current_user = socket.assigns.current_user
      
      # Create a custom prompt based on the trending topic
      prompt = "Write a social media post about '#{topic}' from a Bangalore perspective. Make it engaging, local, and conversational."
      
      # Check if we have OpenAI API configured, otherwise provide a template
      case System.get_env("OPENAI_API_KEY") do
        nil ->
          # Fallback content when no API key
          template_content = "💭 Thinking about #{topic} today... What's your take on this, Bangalore? #Bangalore"
          send(self(), {:ai_generated_content, template_content})
          
          try do
            send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
              id: component_id, 
              action: :generation_complete)
          rescue
            _error ->
              Logger.warning("Templates component no longer exists (component_id: #{inspect(component_id)})")
          end
          
        _api_key ->
          case AIEnhancer.enhance_message(prompt, current_user) do
            {:ok, generated_content} ->
              # Clean up the generated content
              cleaned_content = generated_content
              |> String.trim()
              |> String.replace(~r/^["']/, "")
              |> String.replace(~r/["']$/, "")
              
              send(self(), {:ai_generated_content, cleaned_content})
              
              try do
                send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
                  id: component_id, 
                  action: :generation_complete)
              rescue
                _error ->
                  Logger.warning("Templates component no longer exists (component_id: #{inspect(component_id)})")
              end
            
            {:error, reason} ->
              try do
                send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
                  id: component_id, 
                  action: {:generation_failed, "Content generation failed: #{reason}"})
              rescue
                _error ->
                  Logger.warning("Templates component no longer exists (component_id: #{inspect(component_id)})")
              end
          end
      end
    rescue
      error ->
        Logger.error("AI Topic Generation crashed: #{inspect(error)}")
        try do
          send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
            id: component_id, 
            action: {:generation_failed, "Topic generation encountered an error"})
        rescue
          _error ->
            Logger.warning("Templates component no longer exists (component_id: #{inspect(component_id)})")
        end
    end
    
    {:noreply, socket}
  end

  def handle_info({:generate_post_from_trending, topic, hashtag, component_id}, socket) do
    require Logger
    Logger.info("Received generate_post_from_trending: topic=#{topic}, hashtag=#{hashtag}, component_id=#{inspect(component_id)}")
    
    try do
      current_user = socket.assigns.current_user
      
      # Create a more specific prompt based on the trending topic and hashtag
      prompt = "Write a social media post about '#{topic}' from a Bangalore perspective. Include the hashtag '#{hashtag}' naturally in the post. Make it engaging, trendy, and relevant to what's happening right now in Bangalore."
      
      # Check if we have OpenAI API configured, otherwise provide a template
      case System.get_env("OPENAI_API_KEY") do
        nil ->
          # Fallback content when no API key
          template_content = "🌟 #{topic} is trending in Bangalore! What are your thoughts on this? #{hashtag} #Bangalore"
          send(self(), {:ai_generated_content, template_content})
          
          try do
            send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
              id: component_id, 
              action: :generation_complete)
          rescue
            _error ->
              Logger.warning("Templates component no longer exists (component_id: #{inspect(component_id)})")
          end
          
        _api_key ->
          case AIEnhancer.enhance_message(prompt, current_user) do
            {:ok, generated_content} ->
              # Clean up the generated content and ensure hashtag is included
              cleaned_content = generated_content
              |> String.trim()
              |> String.replace(~r/^["']/, "")
              |> String.replace(~r/["']$/, "")
              
              # Ensure the hashtag is included if it wasn't generated naturally
              final_content = if String.contains?(cleaned_content, hashtag) do
                cleaned_content
              else
                "#{cleaned_content} #{hashtag}"
              end
              
              send(self(), {:ai_generated_content, final_content})
              
              try do
                send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
                  id: component_id, 
                  action: :generation_complete)
              rescue
                _error ->
                  Logger.warning("Templates component no longer exists (component_id: #{inspect(component_id)})")
              end
            
            {:error, reason} ->
              try do
                send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
                  id: component_id, 
                  action: {:generation_failed, "Content generation failed: #{reason}"})
              rescue
                _error ->
                  Logger.warning("Templates component no longer exists (component_id: #{inspect(component_id)})")
              end
          end
      end
    rescue
      error ->
        Logger.error("AI Trending Generation crashed: #{inspect(error)}")
        try do
          send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
            id: component_id, 
            action: {:generation_failed, "Trending topic generation encountered an error"})
        rescue
          _error ->
            Logger.warning("Templates component no longer exists (component_id: #{inspect(component_id)})")
        end
    end
    
    {:noreply, socket}
  end

  def handle_info({:ai_generated_content, content}, socket) do
    # Update the main post form with the generated content
    enhanced_changeset = Content.change_post(%Post{content: content})
    new_post_form = to_form(enhanced_changeset, as: :post)
    
    # Update viral score predictor with generated content
    send_update(CreamSocialWeb.StreamLive.ViralScoreComponent,
      id: "viral-predictor",
      content: content)
    
    socket = 
      socket
      |> assign(:new_post_form, new_post_form)
      |> put_flash(:info, "✨ AI post generated! Review and post when ready.")
    
    {:noreply, socket}
  end

  def handle_info({:test_generation_complete, component_id}, socket) do
    send_update(CreamSocialWeb.StreamLive.TemplatesComponent, 
      id: component_id, 
      action: :generation_complete)
    {:noreply, socket}
  end

  def handle_info({:flash_message, level, message}, socket) do
    {:noreply, put_flash(socket, level, message)}
  end

  defp list_posts_with_follow_status(current_user_id) do
    posts = Content.list_posts()
    
    # Get all user IDs from posts
    user_ids = posts |> Enum.map(& &1.user_id) |> Enum.uniq()
    
    # Get follow status for all users in one query
    follow_statuses = 
      from(f in CreamSocial.Social.Follow,
        where: f.follower_id == ^current_user_id and f.followed_id in ^user_ids and f.status == "active",
        select: f.followed_id
      )
      |> Repo.all()
      |> MapSet.new()
    
    # Get follow counts for all users in batch
    follow_counts = 
      from(f in CreamSocial.Social.Follow,
        where: f.followed_id in ^user_ids and f.status == "active",
        group_by: f.followed_id,
        select: {f.followed_id, count(f.id)}
      )
      |> Repo.all()
      |> Map.new()
    
    following_counts = 
      from(f in CreamSocial.Social.Follow,
        where: f.follower_id in ^user_ids and f.status == "active",
        group_by: f.follower_id,
        select: {f.follower_id, count(f.id)}
      )
      |> Repo.all()
      |> Map.new()
    
    # Add follow information to each post
    Enum.map(posts, fn post ->
      is_following = MapSet.member?(follow_statuses, post.user_id)
      followers_count = Map.get(follow_counts, post.user_id, 0)
      following_count = Map.get(following_counts, post.user_id, 0)
      
      Map.put(post, :follow_info, %{
        is_following: is_following,
        followers_count: followers_count,
        following_count: following_count
      })
    end)
  end


  defp get_current_user(session) do
    user_token = Map.get(session, "user_token")
    user_token && Accounts.get_user_by_session_token(user_token)
  end

  defp get_current_user_safe(session) do
    try do
      get_current_user(session)
    rescue
      _ -> nil
    end
  end

  defp list_public_posts do
    # Return recent public posts for public viewing
    from(p in Post,
      where: p.visibility == "public" and is_nil(p.deleted_at),
      order_by: [desc: p.inserted_at],
      limit: 20,
      preload: [:user]
    )
    |> Repo.all()
    |> Enum.map(fn post ->
      Map.put(post, :follow_info, %{
        is_following: false,
        followers_count: 0,
        following_count: 0
      })
    end)
  end


  defp get_file_extension(filename) do
    filename
    |> Path.extname()
    |> String.trim_leading(".")
    |> String.downcase()
  end
end