defmodule CreamSocialWeb.StreamLive.UploadComponent do
  use CreamSocialWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mt-4">
      <div class="flex items-center space-x-4">
        <label for={@uploads.media.ref} class="cursor-pointer inline-flex items-center px-3 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50">
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          Add Photos/Videos
        </label>
        <.live_file_input upload={@uploads.media} class="hidden" />
      </div>

      <!-- Preview uploaded files -->
      <div class="mt-4 grid grid-cols-2 gap-4" :if={length(@uploads.media.entries) > 0}>
        <%= for entry <- @uploads.media.entries do %>
          <div class="relative">
            <.live_img_preview entry={entry} class="w-full h-32 object-cover rounded-lg" />
            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              phx-target={@myself}
              class="absolute top-2 right-2 w-6 h-6 bg-red-500 text-white rounded-full flex items-center justify-center text-xs hover:bg-red-600"
            >
              ×
            </button>
            <!-- Progress bar -->
            <div class="absolute bottom-0 left-0 right-0 bg-gray-200 rounded-b-lg">
              <div class="bg-blue-500 h-1 rounded-b-lg transition-all" style={"width: #{entry.progress}%"}></div>
            </div>
          </div>
        <% end %>
      </div>

      <!-- Upload errors -->
      <%= for err <- upload_errors(@uploads.media) do %>
        <div class="mt-2 text-sm text-red-600">
          <%= error_to_string(err) %>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :media, ref)}
  end

  defp error_to_string(:too_large), do: "File too large (max 10MB)"
  defp error_to_string(:too_many_files), do: "Too many files (max 4)"
  defp error_to_string(:not_accepted), do: "Invalid file type"
  defp error_to_string(_), do: "Upload error"
end