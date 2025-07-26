defmodule CreamSocialWeb.SettingsLive.Index do
  use CreamSocialWeb, :live_view
  alias CreamSocial.Accounts
  

  @impl true
  def mount(_params, session, socket) do
    current_user = get_current_user(session)
    
    socket = 
      socket
      |> assign(:current_user, current_user)
      |> assign(:page_title, "Profile Settings")
      |> assign(:profile_form, to_form(Accounts.User.update_changeset(current_user, %{})))
      |> allow_upload(:profile_pic, 
          accept: ~w(.jpg .jpeg .png .gif),
          max_entries: 1,
          max_file_size: 5_000_000)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  @impl true
  def handle_event("update_profile", %{"user" => user_params}, socket) do
    current_user = socket.assigns.current_user
    
    # Handle profile picture upload
    uploaded_files = 
      consume_uploaded_entries(socket, :profile_pic, fn %{path: path}, entry ->
        dest = Path.join(["priv", "static", "uploads", "profile_#{current_user.id}_#{entry.uuid}.#{get_file_extension(entry.client_name)}"])
        
        # Ensure uploads directory exists
        File.mkdir_p!(Path.dirname(dest))
        
        # Copy uploaded file to destination
        File.cp!(path, dest)
        
        # Return the web path
        {:ok, "/uploads/profile_#{current_user.id}_#{entry.uuid}.#{get_file_extension(entry.client_name)}"}
      end)
    
    # Add profile pic to user params if uploaded
    user_params = 
      case uploaded_files do
        [profile_pic_path] -> Map.put(user_params, "profile_pic", profile_pic_path)
        [] -> user_params
      end

    case Accounts.update_user_profile(current_user, user_params) do
      {:ok, updated_user} ->
        socket = 
          socket
          |> put_flash(:info, "Profile updated successfully!")
          |> assign(:current_user, updated_user)
          |> assign(:profile_form, to_form(Accounts.User.update_changeset(updated_user, %{})))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset))}
    end
  end

  def handle_event("validate", %{"user" => _user_params}, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :profile_pic, ref)}
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
end