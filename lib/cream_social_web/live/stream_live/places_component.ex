defmodule CreamSocialWeb.StreamLive.PlacesComponent do
  use CreamSocialWeb, :live_component
  alias CreamSocial.Places
  alias CreamSocial.Places.Place

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow dark:shadow-gray-900/20 p-4 mb-4">
      <!-- Header -->
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
          <svg class="w-5 h-5 mr-2 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          Places Discovery
        </h3>
        <div class="flex items-center space-x-3">
          <%= if @show_places do %>
            <button
              phx-click="toggle_add_form"
              phx-target={@myself}
              class="text-sm text-green-600 hover:text-green-800 dark:text-green-400 dark:hover:text-green-200 flex items-center"
            >
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              Add Place
            </button>
          <% end %>
          <button
            phx-click="toggle_places"
            phx-target={@myself}
            class="text-sm text-indigo-600 hover:text-indigo-800 dark:text-indigo-400 dark:hover:text-indigo-200"
          >
            <%= if @show_places do %>
              Hide Places
            <% else %>
              Discover Places
            <% end %>
          </button>
        </div>
      </div>

      <%= if @show_places do %>
        <!-- Search and Filters -->
        <div class="mb-4 space-y-3">
          <!-- Search Bar -->
          <div class="relative">
            <input
              type="text"
              placeholder="Search places in Bangalore..."
              phx-target={@myself}
              phx-keyup="search_places"
              phx-debounce="300"
              value={@search_term}
              class="w-full px-4 py-2 pl-10 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 dark:bg-gray-700 dark:text-white"
            />
            <svg class="absolute left-3 top-2.5 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>

          <!-- Area Filter -->
          <div class="flex flex-wrap gap-2">
            <%= for area <- @bangalore_areas do %>
              <button
                phx-click="select_area"
                phx-value-area={area}
                phx-target={@myself}
                class={[
                  "px-3 py-1 text-xs rounded-full transition-colors",
                  if(@selected_area == area, 
                    do: "bg-indigo-500 text-white", 
                    else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
                  )
                ]}
              >
                <%= area_display_name(area) %>
              </button>
            <% end %>
          </div>

          <!-- Category Filter -->
          <div class="flex flex-wrap gap-2">
            <%= for {category, info} <- @categories do %>
              <button
                phx-click="select_category"
                phx-value-category={category}
                phx-target={@myself}
                class={[
                  "px-3 py-1 text-xs rounded-full transition-colors flex items-center",
                  if(@selected_category == category, 
                    do: "bg-blue-500 text-white", 
                    else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
                  )
                ]}
              >
                <span class="mr-1"><%= info.icon %></span>
                <%= info.name %>
              </button>
            <% end %>
          </div>
        </div>

        <!-- Add Place Form -->
        <%= if @show_add_form do %>
          <div class="border border-green-200 dark:border-green-700 rounded-lg p-4 mb-4 bg-green-50 dark:bg-green-900/20">
            <h4 class="text-lg font-medium text-green-900 dark:text-green-100 mb-3 flex items-center">
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              Add New Place to Bangalore
            </h4>
            
            <.form for={@add_place_form} phx-submit="create_place" phx-change="validate_place" phx-target={@myself} class="space-y-4">
              <!-- Basic Info Row -->
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Place Name *</label>
                  <.input 
                    field={@add_place_form[:name]} 
                    type="text" 
                    placeholder="e.g., Toit Brewpub"
                    required
                    class="w-full"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Category *</label>
                  <.input 
                    field={@add_place_form[:category]} 
                    type="select"
                    options={Place.category_options()}
                    required
                    class="w-full"
                  />
                </div>
              </div>

              <!-- Location Row -->
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Area *</label>
                  <.input 
                    field={@add_place_form[:area]} 
                    type="select"
                    options={Place.area_options()}
                    required
                    class="w-full"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Price Range</label>
                  <.input 
                    field={@add_place_form[:price_range]} 
                    type="select"
                    options={[{"Budget (₹)", "budget"}, {"Mid Range (₹₹)", "mid_range"}, {"Expensive (₹₹₹)", "expensive"}]}
                    class="w-full"
                  />
                </div>
              </div>

              <!-- Description -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Description</label>
                <.input 
                  field={@add_place_form[:description]} 
                  type="textarea"
                  rows="2"
                  placeholder="Describe what makes this place special..."
                  class="w-full"
                />
              </div>

              <!-- Address -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Address</label>
                <.input 
                  field={@add_place_form[:address]} 
                  type="textarea"
                  rows="2"
                  placeholder="Full address including landmarks"
                  class="w-full"
                />
              </div>

              <!-- Image URL -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Image URL</label>
                <.input 
                  field={@add_place_form[:image_url]} 
                  type="url"
                  placeholder="https://example.com/image.jpg (Optional - adds visual appeal!)"
                  class="w-full"
                />
                <p class="text-xs text-gray-500 mt-1">💡 Pro tip: Add an image URL to make your place more discoverable!</p>
              </div>

              <!-- Contact Info Row -->
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Phone Number</label>
                  <.input 
                    field={@add_place_form[:phone]} 
                    type="tel"
                    placeholder="+91 98765 43210"
                    class="w-full"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Website</label>
                  <.input 
                    field={@add_place_form[:website]} 
                    type="url"
                    placeholder="https://example.com"
                    class="w-full"
                  />
                </div>
              </div>

              <!-- Amenities Checkboxes -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Amenities</label>
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  <label class="flex items-center text-sm text-gray-700 dark:text-gray-300">
                    <.input field={@add_place_form[:wifi_available]} type="checkbox" class="mr-2" />
                    📶 WiFi
                  </label>
                  <label class="flex items-center text-sm text-gray-700 dark:text-gray-300">
                    <.input field={@add_place_form[:parking_available]} type="checkbox" class="mr-2" />
                    🅿️ Parking
                  </label>
                  <label class="flex items-center text-sm text-gray-700 dark:text-gray-300">
                    <.input field={@add_place_form[:wheelchair_accessible]} type="checkbox" class="mr-2" />
                    ♿ Accessible
                  </label>
                  <label class="flex items-center text-sm text-gray-700 dark:text-gray-300">
                    <.input field={@add_place_form[:outdoor_seating]} type="checkbox" class="mr-2" />
                    🌿 Outdoor
                  </label>
                </div>
              </div>

              <!-- Form Actions -->
              <div class="flex justify-between items-center pt-2">
                <button
                  type="button"
                  phx-click="toggle_add_form"
                  phx-target={@myself}
                  class="text-sm text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                >
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                  </svg>
                  Add Place
                </button>
              </div>
            </.form>
          </div>
        <% end %>

        <!-- Places Grid -->
        <%= if length(@places) > 0 do %>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
            <%= for place <- @places do %>
              <div class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden hover:border-indigo-300 dark:hover:border-indigo-600 transition-colors">
                <!-- Place Image -->
                <%= if place.image_url do %>
                  <div class="aspect-w-16 aspect-h-9 bg-gray-200">
                    <img 
                      src={place.image_url} 
                      alt={place.name}
                      class="w-full h-48 object-cover"
                      loading="lazy"
                      onerror="this.src='/images/placeholder-place.jpg';this.onerror=null;"
                    />
                  </div>
                <% else %>
                  <div class="h-48 bg-gradient-to-br from-indigo-100 to-purple-100 dark:from-gray-700 dark:to-gray-600 flex items-center justify-center">
                    <div class="text-center text-gray-500 dark:text-gray-400">
                      <span class="text-4xl"><%= get_category_icon(place.category) %></span>
                      <p class="text-sm mt-2">No image available</p>
                    </div>
                  </div>
                <% end %>
                
                <div class="p-4">
                  <!-- Place Header -->
                  <div class="flex items-start justify-between mb-2">
                    <div class="flex-1">
                      <h4 class="font-medium text-gray-900 dark:text-white flex items-center">
                        <span class="mr-1"><%= get_category_icon(place.category) %></span>
                        <span><%= place.name %></span>
                        <%= if place.featured do %>
                          <span class="ml-1 text-yellow-500">⭐</span>
                        <% end %>
                        <%= if place.created_by do %>
                          <span class="ml-1 text-xs bg-green-100 dark:bg-green-800 text-green-800 dark:text-green-200 px-2 py-1 rounded-full">Community</span>
                        <% end %>
                      </h4>
                      <p class="text-sm text-gray-600 dark:text-gray-400">
                        <%= area_display_name(place.area) %>
                        <%= if place.price_range do %>
                          • <%= String.replace(place.price_range, "_", " ") |> String.capitalize() %>
                        <% end %>
                        <%= if place.created_by do %>
                          • Added by <%= place.created_by.full_name %>
                        <% end %>
                      </p>
                    </div>
                    <%= if place.community_rating || place.google_rating do %>
                      <div class="text-right">
                        <div class="text-sm font-medium text-gray-900 dark:text-white">
                          <%= display_rating(place) %>
                        </div>
                        <div class="text-xs text-gray-500">
                          <%= display_rating_count(place) %>
                        </div>
                      </div>
                    <% end %>
                  </div>

                <!-- Place Description -->
                <%= if place.description do %>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mb-2 line-clamp-2">
                    <%= place.description %>
                  </p>
                <% end %>

                <!-- Amenities -->
                <%= if length(place.amenities) > 0 do %>
                  <div class="flex flex-wrap gap-1 mb-3">
                    <%= for amenity <- Enum.take(place.amenities, 3) do %>
                      <span class="inline-flex items-center px-2 py-1 rounded-full text-xs bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300">
                        <%= amenity_icon(amenity) %> <%= String.replace(amenity, "_", " ") |> String.capitalize() %>
                      </span>
                    <% end %>
                    <%= if length(place.amenities) > 3 do %>
                      <span class="text-xs text-gray-500">+<%= length(place.amenities) - 3 %> more</span>
                    <% end %>
                  </div>
                <% end %>

                  <!-- Action Buttons -->
                  <div class="flex items-center justify-between pt-2">
                    <div class="flex space-x-3">
                      <button
                        phx-click="view_place"
                        phx-value-place_id={place.id}
                        phx-target={@myself}
                        class="text-sm text-indigo-600 dark:text-indigo-400 hover:text-indigo-800 dark:hover:text-indigo-200"
                      >
                        View Details
                      </button>
                      <%= if place.address || (place.latitude && place.longitude) do %>
                        <a
                          href={get_directions_url(place)}
                          target="_blank"
                          rel="noopener noreferrer"
                          class="text-sm text-green-600 dark:text-green-400 hover:text-green-800 dark:hover:text-green-200 flex items-center"
                        >
                          <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-1.447-.894L15 4m0 13V4m0 0L9 7"/>
                          </svg>
                          Directions
                        </a>
                      <% end %>
                    </div>
                    <button
                      phx-click="share_place"
                      phx-value-place_id={place.id}
                      phx-target={@myself}
                      class="text-sm text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200"
                    >
                      Share 📤
                    </button>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <div class="text-center py-8">
            <div class="text-gray-400 dark:text-gray-500 mb-2">
              <svg class="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
            <p class="text-gray-600 dark:text-gray-400 mb-2">
              <%= if @search_term != "" or @selected_area != "" or @selected_category != "" do %>
                No places found matching your criteria
              <% else %>
                Discover amazing places in Bangalore!
              <% end %>
            </p>
            <p class="text-sm text-gray-500">
              Try selecting an area or category above
            </p>
          </div>
        <% end %>

        <!-- Featured Section -->
        <%= if @selected_area == "" and @selected_category == "" and @search_term == "" do %>
          <%= if length(@featured_places) > 0 do %>
            <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
              <h4 class="text-sm font-medium text-gray-800 dark:text-gray-200 mb-2 flex items-center">
                ⭐ Featured Places in Bangalore
              </h4>
              <div class="flex flex-wrap gap-2">
                <%= for place <- Enum.take(@featured_places, 4) do %>
                  <button
                    phx-click="view_place"
                    phx-value-place_id={place.id}
                    phx-target={@myself}
                    class="flex items-center px-3 py-2 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-700 rounded-md text-sm text-yellow-800 dark:text-yellow-200 hover:bg-yellow-100 dark:hover:bg-yellow-900/30 transition-colors"
                  >
                    <%= get_category_icon(place.category) %>
                    <span class="ml-1"><%= place.name %></span>
                    <span class="ml-2 text-yellow-500">⭐</span>
                  </button>
                <% end %>
              </div>
            </div>
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket = 
      socket
      |> assign(:show_places, false)
      |> assign(:places, [])
      |> assign(:featured_places, [])
      |> assign(:search_term, "")
      |> assign(:selected_area, "")
      |> assign(:selected_category, "")
      |> assign(:bangalore_areas, get_popular_areas())
      |> assign(:categories, Place.categories())
      |> assign(:show_add_form, false)
      |> assign(:add_place_form, to_form(Places.change_place(%Place{})))

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("toggle_places", _params, socket) do
    show_places = !socket.assigns.show_places
    
    socket = socket
    |> assign(:show_places, show_places)
    
    # Load featured places when showing for the first time
    socket = if show_places and socket.assigns.featured_places == [] do
      featured_places = Places.get_featured_places(6)
      assign(socket, :featured_places, featured_places)
    else
      socket
    end
    
    {:noreply, socket}
  end

  def handle_event("search_places", %{"value" => search_term}, socket) do
    places = if String.trim(search_term) != "" do
      Places.search_places(search_term, %{limit: 8})
    else
      []
    end
    
    socket = 
      socket
      |> assign(:search_term, search_term)
      |> assign(:places, places)
      |> assign(:selected_area, "")
      |> assign(:selected_category, "")
    
    {:noreply, socket}
  end

  def handle_event("select_area", %{"area" => area}, socket) do
    selected_area = if socket.assigns.selected_area == area, do: "", else: area
    
    places = if selected_area != "" do
      Places.discover_places(selected_area, socket.assigns.selected_category, %{limit: 8})
    else
      []
    end
    
    socket = 
      socket
      |> assign(:selected_area, selected_area)
      |> assign(:places, places)
      |> assign(:search_term, "")
    
    {:noreply, socket}
  end

  def handle_event("select_category", %{"category" => category}, socket) do
    selected_category = if socket.assigns.selected_category == category, do: "", else: category
    
    places = if socket.assigns.selected_area != "" or selected_category != "" do
      area = if socket.assigns.selected_area != "", do: socket.assigns.selected_area, else: nil
      cat = if selected_category != "", do: selected_category, else: nil
      
      if area do
        Places.discover_places(area, cat, %{limit: 8})
      else
        # Search across all areas for this category
        Places.list_places(%{category: cat, limit: 8})
      end
    else
      []
    end
    
    socket = 
      socket
      |> assign(:selected_category, selected_category)
      |> assign(:places, places)
      |> assign(:search_term, "")
    
    {:noreply, socket}
  end

  def handle_event("view_place", %{"place_id" => place_id}, socket) do
    # TODO: Navigate to place detail page or open modal
    # For now, just show a flash message
    send(self(), {:flash_message, :info, "Place details coming soon! 🏪"})
    {:noreply, socket}
  end

  def handle_event("share_place", %{"place_id" => place_id, "content" => content}, socket) do
    # Generate content for the main post textarea
    try do
      place = Places.get_place!(String.to_integer(place_id))
      content = "Just discovered #{place.name} in #{area_display_name(place.area)}! #{get_category_icon(place.category)} #{if place.description, do: place.description, else: "Great place to check out!"} #Bangalore ##{String.replace(place.area, "_", "")}"
      
      send(self(), {:ai_generated_content, content})
      send(self(), {:flash_message, :info, "✨ Place shared to your post!"})
      {:noreply, socket}
    rescue
      _ ->
        send(self(), {:flash_message, :error, "Place not found"})
        {:noreply, socket}
    end
  end

  def handle_event("toggle_add_form", _params, socket) do
    show_add_form = !socket.assigns.show_add_form
    
    socket = 
      socket
      |> assign(:show_add_form, show_add_form)
      |> assign(:add_place_form, to_form(Places.change_place(%Place{})))
    
    {:noreply, socket}
  end

  def handle_event("validate_place", %{"place" => place_params}, socket) do
    changeset = Places.change_place(%Place{}, place_params)
    form = to_form(changeset, action: :validate)
    
    socket = assign(socket, :add_place_form, form)
    {:noreply, socket}
  end

  def handle_event("create_place", %{"place" => place_params}, socket) do
    current_user = socket.assigns.current_user
    
    place_params = 
      place_params
      |> Map.put("created_by_id", current_user.id)
      |> Map.put("status", "active")
    
    case Places.create_place(place_params) do
      {:ok, place} ->
        socket = 
          socket
          |> assign(:show_add_form, false)
          |> assign(:add_place_form, to_form(Places.change_place(%Place{})))
        
        send(self(), {:flash_message, :info, "🎉 Place '#{place.name}' added successfully! Thanks for contributing!"})
        
        # Refresh places if we're in the same area or category
        socket = refresh_places_if_match(socket, place)
        
        {:noreply, socket}
        
      {:error, %Ecto.Changeset{} = changeset} ->
        form = to_form(changeset, action: :validate)
        socket = assign(socket, :add_place_form, form)
        {:noreply, socket}
    end
  end

  # Helper functions
  defp refresh_places_if_match(socket, new_place) do
    # If the user is currently viewing the same area or category, refresh the list
    cond do
      socket.assigns.selected_area == new_place.area ->
        places = Places.discover_places(new_place.area, socket.assigns.selected_category, %{limit: 8})
        assign(socket, :places, places)
      
      socket.assigns.selected_category == new_place.category && socket.assigns.selected_area == "" ->
        places = Places.list_places(%{category: new_place.category, limit: 8})
        assign(socket, :places, places)
      
      true ->
        socket
    end
  end

  defp get_popular_areas do
    [
      "koramangala", "indiranagar", "whitefield", "electronic_city",
      "jayanagar", "malleswaram", "banashankari", "hsr_layout",
      "marathahalli", "bellandur", "mg_road", "brigade_road"
    ]
  end

  defp area_display_name(area) do
    area
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp get_category_icon(category) do
    case Place.categories()[category] do
      %{icon: icon} -> icon
      _ -> "📍"
    end
  end

  defp display_rating(place) do
    cond do
      place.community_rating -> "#{place.community_rating}/5"
      place.google_rating -> "#{place.google_rating}/5"
      true -> "New"
    end
  end

  defp display_rating_count(place) do
    cond do
      place.community_total_ratings && place.community_total_ratings > 0 -> 
        "#{place.community_total_ratings} reviews"
      place.google_total_ratings && place.google_total_ratings > 0 -> 
        "#{place.google_total_ratings} Google reviews"
      true -> "No reviews yet"
    end
  end

  defp amenity_icon(amenity) do
    case amenity do
      "wifi" -> "📶"
      "parking" -> "🅿️"
      "ac" -> "❄️"
      "outdoor_seating" -> "🌿"
      "live_music" -> "🎵"
      "wheelchair_accessible" -> "♿"
      _ -> "✓"
    end
  end

  defp get_directions_url(place) do
    cond do
      # If we have coordinates, use them for precise navigation
      place.latitude && place.longitude ->
        "https://www.google.com/maps/dir/?api=1&destination=#{place.latitude},#{place.longitude}"
      
      # If we have an address, use that
      place.address && String.trim(place.address) != "" ->
        address = URI.encode(place.address)
        "https://www.google.com/maps/dir/?api=1&destination=#{address}"
      
      # Fallback to place name + area
      true ->
        destination = URI.encode("#{place.name}, #{area_display_name(place.area)}, Bangalore")
        "https://www.google.com/maps/dir/?api=1&destination=#{destination}"
    end
  end
end