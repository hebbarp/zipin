defmodule CreamSocialWeb.LinkPreviewComponent do
  use CreamSocialWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mt-4 space-y-3">
      <%= if length(@link_previews) > 0 do %>
        <div
          :for={preview <- @link_previews}
          class="border border-gray-200 dark:border-gray-600 rounded-lg overflow-hidden hover:border-gray-300 dark:hover:border-gray-500 transition-colors max-w-full bg-white dark:bg-gray-800"
        >
          <a href={preview.url} target="_blank" rel="noopener noreferrer" class="block">
            <%= if preview.image_url do %>
              <!-- Mobile: smaller aspect ratio, Desktop: video aspect ratio -->
              <div class="aspect-[4/3] sm:aspect-video w-full bg-gray-100 dark:bg-gray-700">
                <img 
                  src={preview.image_url} 
                  alt={preview.title || "Link preview image"}
                  class="w-full h-full object-cover"
                  onerror="this.parentElement.style.display='none'"
                />
              </div>
            <% end %>
            
            <!-- Mobile: smaller padding, Desktop: normal padding -->
            <div class="p-3 sm:p-4">
              <%= if preview.title do %>
                <!-- Mobile: smaller text, Desktop: normal text -->
                <h4 class="font-semibold text-gray-900 dark:text-white mb-2 text-sm sm:text-base leading-tight sm:leading-normal" style="display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">
                  <%= preview.title %>
                </h4>
              <% end %>
              
              <%= if preview.description do %>
                <!-- Mobile: smaller text and fewer lines, Desktop: normal -->
                <p class="text-gray-600 dark:text-gray-300 text-xs sm:text-sm mb-2 leading-tight sm:leading-normal" style="display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">
                  <%= preview.description %>
                </p>
              <% end %>
              
              <!-- Mobile: stack on very small screens, flex on larger -->
              <div class="flex flex-col xs:flex-row xs:items-center text-xs text-gray-500 dark:text-gray-400 space-y-1 xs:space-y-0">
                <%= if preview.site_name do %>
                  <span class="font-medium"><%= preview.site_name %></span>
                  <span class="hidden xs:inline mx-2">•</span>
                <% end %>
                <span class="text-gray-400 dark:text-gray-500"><%= URI.parse(preview.url).host %></span>
              </div>
            </div>
          </a>
        </div>
      <% end %>
    </div>
    """
  end
end