defmodule CreamSocialWeb.MobileNav do
  use Phoenix.Component
  
  use CreamSocialWeb, :verified_routes
  
  attr :current_user, :map, required: true
  attr :current_page, :string, default: "stream"
  
  def mobile_bottom_nav(assigns) do
    ~H"""
    <!-- Mobile Bottom Navigation -->
    <nav class="md:hidden fixed bottom-0 left-0 right-0 bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 z-50">
      <div class="grid grid-cols-5 h-16">
        <!-- Feed -->
        <.link navigate={~p"/stream"} class={[
          "flex flex-col items-center justify-center text-xs transition-colors",
          if(@current_page == "stream", do: "text-orange-600 dark:text-orange-400", else: "text-gray-600 dark:text-gray-400")
        ]}>
          <svg class="w-6 h-6 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m7 7 5 5 5-5" />
          </svg>
          <span>Feed</span>
        </.link>

        <!-- Places -->
        <.link navigate={~p"/stream?tab=places"} class={[
          "flex flex-col items-center justify-center text-xs transition-colors",
          if(@current_page == "places", do: "text-orange-600 dark:text-orange-400", else: "text-gray-600 dark:text-gray-400")
        ]}>
          <svg class="w-6 h-6 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <span>Places</span>
        </.link>

        <!-- Events -->  
        <.link navigate={~p"/stream?tab=events"} class={[
          "flex flex-col items-center justify-center text-xs transition-colors",
          if(@current_page == "events", do: "text-orange-600 dark:text-orange-400", else: "text-gray-600 dark:text-gray-400")
        ]}>
          <svg class="w-6 h-6 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 002 2z" />
          </svg>
          <span>Events</span>
        </.link>

        <!-- Messages -->
        <.link navigate={~p"/messages"} class={[
          "flex flex-col items-center justify-center text-xs transition-colors relative",
          if(@current_page == "messages", do: "text-orange-600 dark:text-orange-400", else: "text-gray-600 dark:text-gray-400")
        ]}>
          <svg class="w-6 h-6 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
          </svg>
          <!-- Message notification badge -->
          <span class="absolute -top-1 -right-1 inline-flex items-center justify-center w-4 h-4 text-xs font-bold leading-none text-white bg-red-600 rounded-full" id="mobile-message-badge" style="display: none;">
            0
          </span>
          <span>Messages</span>
        </.link>

        <!-- Profile/Settings -->
        <.link navigate={~p"/settings"} class={[
          "flex flex-col items-center justify-center text-xs transition-colors",
          if(@current_page == "settings", do: "text-orange-600 dark:text-orange-400", else: "text-gray-600 dark:text-gray-400")
        ]}>
          <div class="w-6 h-6 mb-1 rounded-full bg-gradient-to-r from-orange-400 to-green-400 flex items-center justify-center text-white text-sm font-bold">
            <%= if @current_user.full_name, do: String.first(@current_user.full_name), else: "U" %>
          </div>
          <span>Profile</span>
        </.link>
      </div>
    </nav>
    
    <!-- Bottom padding to account for fixed navigation -->
    <div class="md:hidden h-16"></div>
    """
  end
end