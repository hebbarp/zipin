defmodule CreamSocialWeb.StreamLive.EventsComponent do
  use CreamSocialWeb, :live_component
  alias CreamSocial.Events
  alias CreamSocial.Events.Event
  alias CreamSocial.Places
  alias CreamSocial.Locations.City

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    require Logger
    Logger.debug("=== EVENTS COMPONENT UPDATE CALLED ===")
    Logger.debug("Assigns: #{inspect(Map.keys(assigns))}")
    
    socket = 
      socket
      |> assign(assigns)
      |> assign_defaults()
      |> load_events()
    
    Logger.debug("=== EVENTS COMPONENT UPDATE COMPLETED ===")
    {:ok, socket}
  end

  def handle_event("filter_by_category", %{"category" => category}, socket) do
    socket = 
      socket
      |> assign(:selected_category, category)
      |> load_events()
    
    {:noreply, socket}
  end

  def handle_event("filter_by_area", %{"area" => area}, socket) do
    socket = 
      socket
      |> assign(:selected_area, area)
      |> load_events()
    
    {:noreply, socket}
  end

  def handle_event("search_events", params, socket) do
    query = case params do
      %{"_target" => ["query"], "query" => query} -> query
      %{"query" => query} -> query
      _ -> ""
    end
    
    socket = 
      socket
      |> assign(:search_query, query)
      |> load_events()
    
    {:noreply, socket}
  end

  def handle_event("share_event", %{"event_id" => event_id}, socket) do
    case Events.get_event(event_id) do
      nil -> {:noreply, socket}
      event ->
        event_text = format_event_for_sharing(event)
        send(self(), {:share_content, event_text})
        {:noreply, socket}
    end
  end

  def handle_event("toggle_rsvp", %{"event_id" => event_id, "status" => status}, socket) do
    user = socket.assigns[:current_user]
    
    if user do
      case Events.get_user_rsvp(event_id, user.id) do
        nil -> 
          Events.create_rsvp(event_id, user.id, %{"status" => status})
        rsvp -> 
          Events.update_rsvp(rsvp, %{"status" => status})
      end
      
      socket = load_events(socket)
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "Please login to RSVP for events")}
    end
  end

  def handle_event("toggle_add_form", _params, socket) do
    require Logger
    Logger.error("=== TOGGLE ADD FORM CLICKED ===")
    
    show_add_form = !Map.get(socket.assigns, :show_add_form, false)
    
    socket = 
      socket
      |> assign(:show_add_form, show_add_form)
      |> assign(:selected_place, nil)  # Clear selected place when toggling
      |> assign(:venue_search_results, [])  # Clear search results
    
    Logger.error("Form toggled to: #{show_add_form}")
    {:noreply, socket}
  end

  def handle_event("validate_event", %{"event" => event_params}, socket) do
    changeset = 
      %Event{}
      |> Events.change_event(event_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :event_changeset, changeset)}
  end

  def handle_event("hide_event_form", _, socket) do
    socket = assign(socket, :show_add_form, false)
    {:noreply, socket}
  end

  def handle_event("toggle_events", _, socket) do
    socket = assign(socket, :events_expanded, !socket.assigns.events_expanded)
    {:noreply, socket}
  end

  def handle_event("search_places_for_venue", %{"key" => _key, "value" => query}, socket) do
    require Logger
    Logger.error("=== VENUE SEARCH ===")
    Logger.error("Query: #{query}")
    
    search_results = 
      if String.length(query) >= 2 do
        results = Places.search_places(query, %{limit: 10})
        Logger.error("Search results: #{length(results)} places found")
        results
      else
        Logger.error("Query too short, returning empty results")
        []
      end
    
    socket = assign(socket, :venue_search_results, search_results)
    {:noreply, socket}
  end

  def handle_event("select_place_for_event", %{"place_id" => place_id}, socket) do
    case Places.get_place(place_id) do
      nil -> {:noreply, socket}
      place ->
        socket = 
          socket
          |> assign(:selected_place, place)
          |> assign(:venue_search_results, [])  # Clear search results
        {:noreply, socket}
    end
  end

  def handle_event("clear_selected_place", _, socket) do
    socket = assign(socket, :selected_place, nil)
    {:noreply, socket}
  end

  def handle_event("create_event", %{"event" => event_params}, socket) do
    require Logger
    Logger.error("=== CREATE EVENT SUBMITTED ===")
    Logger.error("Event params: #{inspect(event_params)}")
    
    user = socket.assigns[:current_user]
    
    if user do
      # Prepare event params for database
      event_params = 
        event_params
        |> Map.put("organizer_id", user.id)
        |> Map.put("status", "active")
        |> Map.put("visibility", "public")
        |> Map.put("is_free", Map.get(event_params, "ticket_price", "") == "")
        |> convert_datetime_params()
      
      Logger.error("Processed event params: #{inspect(event_params)}")
      
      try do
        case Events.create_event(event_params) do
          {:ok, event} ->
            Logger.error("Event created successfully: #{inspect(event)}")
            socket = 
              socket
              |> assign(:show_add_form, false)
              |> assign(:selected_place, nil)  # Clear selected place
              |> assign(:venue_search_results, [])  # Clear search results
              |> load_events()  # Reload events to show the new one
              |> put_flash(:info, "Event '#{event.title}' created successfully!")
            
            {:noreply, socket}
          
          {:error, changeset} ->
            Logger.error("Event creation failed with changeset: #{inspect(changeset)}")
            Logger.error("Changeset errors: #{inspect(changeset.errors)}")
            
            error_messages = 
              changeset.errors
              |> Enum.map(fn {field, {message, _}} -> "#{field}: #{message}" end)
              |> Enum.join(", ")
            
            socket = 
              socket
              |> put_flash(:error, "Failed to create event: #{error_messages}")
            # Don't clear form state on error - keep it open so user can fix issues
            
            {:noreply, socket}
        end
      rescue
        error ->
          Logger.error("Event creation crashed: #{inspect(error)}")
          Logger.error("Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
          
          socket = 
            socket
            |> put_flash(:error, "Event creation failed unexpectedly. Please try again.")
          
          {:noreply, socket}
      end
    else
      {:noreply, put_flash(socket, :error, "Please login to create events")}
    end
  end

  defp convert_datetime_params(params) do
    params =
      if start_datetime = params["start_datetime"] do
        case DateTime.from_iso8601(start_datetime <> ":00Z") do
          {:ok, datetime, _} -> Map.put(params, "start_datetime", datetime)
          _ -> params
        end
      else
        params
      end

    if end_datetime = params["end_datetime"] do
      case DateTime.from_iso8601(end_datetime <> ":00Z") do
        {:ok, datetime, _} -> Map.put(params, "end_datetime", datetime)
        _ -> params
      end
    else
      params
    end
  end

  def handle_event(event_name, params, socket) do
    require Logger
    Logger.error("=== UNHANDLED EVENT IN EVENTS COMPONENT ===")
    Logger.error("Event: #{event_name}")
    Logger.error("Params: #{inspect(params)}")
    Logger.error("Socket assigns: #{inspect(Map.keys(socket.assigns))}")
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow dark:shadow-gray-900/20 p-4 mb-4">
      <!-- Header -->
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
          <svg class="w-5 h-5 mr-2 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          Events & Meetups
        </h3>
        <div class="flex items-center space-x-3">
          <%= if @events_expanded do %>
            <button
              phx-click="toggle_add_form"
              phx-target={@myself}
              class="text-sm text-green-600 hover:text-green-800 dark:text-green-400 dark:hover:text-green-200 flex items-center"
              data-test="add-event-button"
            >
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              Add Event
            </button>
          <% end %>
          <button
            phx-click="toggle_events"
            phx-target={@myself}
            class="text-sm text-indigo-600 hover:text-indigo-800 dark:text-indigo-400 dark:hover:text-indigo-200"
          >
            <%= if @events_expanded do %>
              Hide Events
            <% else %>
              Discover Events
            <% end %>
          </button>
        </div>
      </div>

      <%= if @events_expanded do %>

      <!-- Add Event Form -->
      <%= if @show_add_form do %>
        <div class="border border-green-200 dark:border-green-700 rounded-lg p-4 mb-4 bg-green-50 dark:bg-green-900/20">
          <h4 class="text-lg font-medium text-green-900 dark:text-green-100 mb-3 flex items-center">
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            Add New Event
          </h4>
          
          <form phx-submit="create_event" phx-target={@myself} class="space-y-4">
            <div>
              <label>Event Title *</label>
              <input name="event[title]" type="text" required class="w-full px-3 py-2 border rounded-md" />
            </div>

            <div>
              <label>Category *</label>
              <select name="event[category]" required class="w-full px-3 py-2 border rounded-md">
                <option value="">Select category</option>
                <option value="tech">Tech & Startups</option>
                <option value="social">Social & Networking</option>
                <option value="sports">Sports & Fitness</option>
                <option value="culture">Arts & Culture</option>
              </select>
            </div>

            <div>
              <label>Start Date & Time *</label>
              <input name="event[start_datetime]" type="datetime-local" required class="w-full px-3 py-2 border rounded-md" />
            </div>

            <!-- Venue Selection -->
            <%= if @selected_place do %>
              <div>
                <label>Selected Venue</label>
                <div class="bg-blue-50 p-3 rounded-lg border border-blue-200 mb-2">
                  <div class="flex justify-between items-start">
                    <div>
                      <h4 class="font-medium text-blue-900"><%= @selected_place.name %></h4>
                      <p class="text-sm text-blue-700"><%= @selected_place.address %></p>
                    </div>
                    <button 
                      type="button"
                      phx-click="clear_selected_place" 
                      phx-target={@myself}
                      class="text-blue-400 hover:text-blue-600 text-sm"
                    >
                      ✕
                    </button>
                  </div>
                </div>
                <input type="hidden" name="event[place_id]" value={@selected_place.id} />
                <input type="hidden" name="event[venue_name]" value={@selected_place.name} />
                <input type="hidden" name="event[venue_address]" value={@selected_place.address} />
                <input type="hidden" name="event[area]" value={@selected_place.area} />
              </div>
            <% else %>
              <div>
                <label>Venue Search</label>
                <input 
                  type="text" 
                  placeholder="Search for a venue..." 
                  phx-keyup="search_places_for_venue"
                  phx-target={@myself}
                  phx-debounce="300"
                  class="w-full px-3 py-2 border rounded-md mb-2"
                />
                
                <%= if length(@venue_search_results) > 0 do %>
                  <div class="border rounded-md max-h-40 overflow-y-auto mb-2">
                    <%= for place <- @venue_search_results do %>
                      <button 
                        type="button"
                        phx-click="select_place_for_event" 
                        phx-value-place_id={place.id} 
                        phx-target={@myself}
                        class="w-full text-left p-2 hover:bg-gray-50 border-b last:border-b-0"
                      >
                        <div class="font-medium"><%= place.name %></div>
                        <div class="text-sm text-gray-600"><%= place.address %></div>
                      </button>
                    <% end %>
                  </div>
                <% end %>
                
                <div class="text-center text-sm text-gray-500 mb-2">Or enter manually:</div>
                <input name="event[venue_name]" type="text" placeholder="Venue name" class="w-full px-3 py-2 border rounded-md" />
              </div>
            <% end %>

            <button type="submit" class="px-4 py-2 bg-green-600 text-white rounded-md">
              Create Event
            </button>
          </form>
        </div>
      <% end %>

      <!-- Filters -->
      <div class="mb-4 space-y-3">
        <!-- Search -->
        <form phx-change="search_events" phx-target={@myself}>
          <div class="relative">
            <input 
              type="text"
              name="query"
              placeholder="Search events..."
              value={@search_query}
              phx-debounce="300"
              class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
            />
            <div class="absolute inset-y-0 left-0 pl-3 flex items-center">
              <span class="text-gray-400">🔍</span>
            </div>
          </div>
        </form>

        <!-- Category Filter -->
        <div class="flex flex-wrap gap-2">
          <button 
            phx-click="filter_by_category" 
            phx-value-category="" 
            phx-target={@myself}
            class={[
              "px-3 py-1 text-sm rounded-full transition-colors",
              if(@selected_category == "", do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")
            ]}
          >
            All
          </button>
          
          <%= for {key, category_info} <- Event.categories() do %>
            <button 
              phx-click="filter_by_category" 
              phx-value-category={key} 
              phx-target={@myself}
              class={[
                "px-3 py-1 text-sm rounded-full transition-colors flex items-center space-x-1",
                if(@selected_category == key, do: "bg-indigo-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")
              ]}
            >
              <span><%= category_info.icon %></span>
              <span><%= category_info.name %></span>
            </button>
          <% end %>
        </div>

        <!-- Area Filter -->
        <div class="flex flex-wrap gap-2">
          <button 
            phx-click="filter_by_area" 
            phx-value-area="" 
            phx-target={@myself}
            class={[
              "px-3 py-1 text-xs rounded-full transition-colors",
              if(@selected_area == "", do: "bg-green-600 text-white", else: "bg-gray-100 text-gray-600 hover:bg-gray-200")
            ]}
          >
            All Areas
          </button>
          
          <%= for area <- @bangalore_areas do %>
            <button 
              phx-click="filter_by_area" 
              phx-value-area={area} 
              phx-target={@myself}
              class={[
                "px-3 py-1 text-xs rounded-full transition-colors",
                if(@selected_area == area, do: "bg-green-600 text-white", else: "bg-gray-100 text-gray-600 hover:bg-gray-200")
              ]}
            >
              <%= City.area_display_name(area) %>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Events List -->
      <div class="space-y-4">
        <%= if Map.get(assigns, :events, []) == [] do %>
          <div class="text-center py-8 text-gray-500">
            <span class="text-4xl mb-2 block">📅</span>
            <p>No events found.</p>
            <p class="text-sm">Try adjusting your filters or create a new event!</p>
          </div>
        <% else %>
          <%= for event <- Map.get(assigns, :events, []) do %>
            <div class="border border-gray-200 rounded-lg p-4 hover:shadow-lg transition-shadow">
              <div class="flex justify-between items-start">
                <div class="flex-1">
                  <div class="flex items-center space-x-2 mb-2">
                    <span class="text-lg"><%= Event.get_category_icon(event.category) %></span>
                    <h3 class="text-lg font-semibold text-gray-900"><%= event.title %></h3>
                    <%= if event.featured do %>
                      <span class="bg-yellow-100 text-yellow-800 text-xs px-2 py-1 rounded-full">Featured</span>
                    <% end %>
                  </div>
                  
                  <div class="text-sm text-gray-600 mb-2 space-y-1">
                    <div class="flex items-center space-x-2">
                      <span>📅</span>
                      <span><%= Event.format_datetime(event.start_datetime) %></span>
                      <%= if event.end_datetime do %>
                        <span>→ <%= Event.format_time(event.end_datetime) %></span>
                      <% end %>
                    </div>
                    
                    <%= if event.venue_name do %>
                      <div class="flex items-center space-x-2">
                        <span>📍</span>
                        <span><%= event.venue_name %></span>
                        <%= if event.area do %>
                          <span class="text-gray-500">• <%= City.area_display_name(event.area) %></span>
                        <% end %>
                      </div>
                    <% end %>

                    <div class="flex items-center space-x-4 text-xs">
                      <span>👥 <%= event.current_attendees %> going</span>
                      <span>👁️ <%= event.views_count %> views</span>
                      <%= if event.is_free do %>
                        <span class="bg-green-100 text-green-700 px-2 py-1 rounded">FREE</span>
                      <% else %>
                        <span class="bg-blue-100 text-blue-700 px-2 py-1 rounded">₹<%= event.ticket_price %></span>
                      <% end %>
                    </div>
                  </div>

                  <%= if event.description do %>
                    <p class="text-gray-700 text-sm mb-3 line-clamp-2"><%= event.description %></p>
                  <% end %>

                  <div class="flex items-center space-x-3">
                    <!-- RSVP Buttons -->
                    <%= if Map.get(assigns, :current_user) do %>
                      <% user_rsvp = get_user_rsvp_status(event.id, @current_user.id, Map.get(assigns, :user_rsvps, %{})) %>
                      <div class="flex space-x-2">
                        <button 
                          phx-click="toggle_rsvp" 
                          phx-value-event_id={event.id}
                          phx-value-status="going"
                          phx-target={@myself}
                          class={[
                            "px-3 py-1 text-xs rounded-full transition-colors",
                            if(user_rsvp == "going", do: "bg-green-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-green-100")
                          ]}
                        >
                          ✅ Going
                        </button>
                        
                        <button 
                          phx-click="toggle_rsvp" 
                          phx-value-event_id={event.id}
                          phx-value-status="maybe"
                          phx-target={@myself}
                          class={[
                            "px-3 py-1 text-xs rounded-full transition-colors",
                            if(user_rsvp == "maybe", do: "bg-yellow-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-yellow-100")
                          ]}
                        >
                          🤔 Maybe
                        </button>
                      </div>
                    <% end %>

                    <%= if event.venue_name || event.venue_address || (event.latitude && event.longitude) do %>
                      <a
                        href={get_directions_url(event)}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="text-green-600 hover:text-green-800 text-sm font-medium flex items-center"
                      >
                        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 013.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-1.447-.894L15 4m0 13V4m0 0L9 7"/>
                        </svg>
                        Directions
                      </a>
                    <% end %>

                    <button 
                      phx-click="share_event" 
                      phx-value-event_id={event.id}
                      phx-target={@myself}
                      class="text-indigo-600 hover:text-indigo-800 text-sm font-medium"
                    >
                      Share Event
                    </button>
                  </div>
                </div>

                <div class="text-right text-xs text-gray-500">
                  <div>by <%= if event.organizer, do: event.organizer.full_name, else: "Unknown" %></div>
                  <div><%= relative_time(event.inserted_at) %></div>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
      <% end %>
    </div>
    """
  end

  # Private Functions

  defp assign_defaults(socket) do
    socket
    |> assign_new(:events, fn -> [] end)
    |> assign_new(:selected_category, fn -> "" end)
    |> assign_new(:selected_area, fn -> "" end)
    |> assign_new(:search_query, fn -> "" end)
    |> assign_new(:show_add_form, fn -> false end)
    |> assign_new(:selected_place, fn -> nil end)
    |> assign_new(:venue_search_results, fn -> [] end)
    |> assign_new(:user_rsvps, fn -> %{} end)
    |> assign_new(:events_expanded, fn -> false end)
    |> assign_new(:bangalore_areas, fn -> 
      ["koramangala", "indiranagar", "whitefield", "electronic_city", 
       "jayanagar", "malleswaram", "banashankari", "btm_layout"]
    end)
  end

  defp load_events(socket) do
    try do
      # Load real events from database
      events = 
        if socket.assigns.search_query != "" do
          # Use search when there's a query
          opts = build_search_options(socket.assigns)
          Events.search_events(socket.assigns.search_query, opts)
        else
          # Use discovery when no search
          opts = build_filter_options(socket.assigns)
          Events.discover_events(opts)
        end
      
      # Load user RSVPs if user is logged in
      user_rsvps = 
        if socket.assigns[:current_user] && length(events) > 0 do
          load_user_rsvps_safe(events, socket.assigns.current_user.id)
        else
          %{}
        end
      
      socket
      |> assign(:events, events)
      |> assign(:user_rsvps, user_rsvps)
    rescue
      error ->
        require Logger
        Logger.error("Events loading failed: #{inspect(error)}")
        
        socket
        |> assign(:events, [])
        |> assign(:user_rsvps, %{})
    end
  end
  
  defp filter_by_search(events, ""), do: events
  defp filter_by_search(events, query) when is_binary(query) do
    query_lower = String.downcase(query)
    
    Enum.filter(events, fn event ->
      String.contains?(String.downcase(event.title), query_lower) or
      String.contains?(String.downcase(event.description), query_lower) or
      String.contains?(String.downcase(event.venue_name), query_lower)
    end)
  end
  
  defp filter_by_category(events, ""), do: events
  defp filter_by_category(events, category) do
    Enum.filter(events, fn event -> event.category == category end)
  end
  
  defp filter_by_area(events, ""), do: events
  defp filter_by_area(events, area) do
    Enum.filter(events, fn event -> event.area == area end)
  end

  defp build_filter_options(assigns) do
    [
      category: (if assigns.selected_category != "", do: assigns.selected_category, else: nil),
      area: (if assigns.selected_area != "", do: assigns.selected_area, else: nil),
      status: "active",
      upcoming: true,
      limit: 20
    ]
    |> Enum.filter(fn {_, v} -> v != nil end)
  end

  defp build_search_options(assigns) do
    [
      category: (if assigns.selected_category != "", do: assigns.selected_category, else: nil),
      area: (if assigns.selected_area != "", do: assigns.selected_area, else: nil),
      status: "active",
      upcoming: true
    ]
    |> Enum.filter(fn {_, v} -> v != nil end)
  end


  defp load_user_rsvps_safe(events, user_id) do
    try do
      # Simple approach - just get RSVPs for the first few events to avoid timeout
      event_ids = events |> Enum.take(5) |> Enum.map(& &1.id)
      
      event_ids
      |> Enum.reduce(%{}, fn event_id, acc ->
        case Events.get_user_rsvp(event_id, user_id) do
          nil -> acc
          rsvp when is_map(rsvp) -> Map.put(acc, event_id, rsvp.status)
          _ -> acc
        end
      end)
    rescue
      _error -> %{}  # Return empty map on any error
    end
  end

  defp get_user_rsvp_status(event_id, _user_id, user_rsvps) do
    Map.get(user_rsvps, event_id)
  end

  defp format_event_for_sharing(event) do
    """
    📅 #{event.title}

    🗓️ #{Event.format_datetime(event.start_datetime)}
    #{if event.venue_name, do: "📍 #{event.venue_name}\n", else: ""}#{if event.description, do: "\n#{event.description}", else: ""}

    #BangaloreEvents ##{String.replace(event.category, " ", "")}
    """
  end

  defp maybe_add_place_details(event_params, nil), do: event_params
  defp maybe_add_place_details(event_params, place) do
    event_params
    |> Map.put("place_id", place.id)
    |> Map.put("venue_name", place.name)
    |> Map.put("venue_address", place.address)
    |> Map.put("area", place.area)
    |> Map.put("latitude", place.latitude)
    |> Map.put("longitude", place.longitude)
  end

  defp relative_time(datetime) do
    seconds_ago = DateTime.diff(DateTime.utc_now(), datetime, :second)
    
    cond do
      seconds_ago < 60 -> "#{seconds_ago}s ago"
      seconds_ago < 3600 -> "#{div(seconds_ago, 60)}m ago"
      seconds_ago < 86400 -> "#{div(seconds_ago, 3600)}h ago"
      true -> "#{div(seconds_ago, 86400)}d ago"
    end
  end

  defp get_directions_url(event) do
    cond do
      # If we have coordinates, use them for precise navigation
      event.latitude && event.longitude ->
        "https://www.google.com/maps/dir/?api=1&destination=#{event.latitude},#{event.longitude}"
      
      # If we have a venue address, use that
      event.venue_address && String.trim(event.venue_address) != "" ->
        address = URI.encode(event.venue_address)
        "https://www.google.com/maps/dir/?api=1&destination=#{address}"
      
      # Fallback to venue name + area
      event.venue_name ->
        destination = if event.area do
          URI.encode("#{event.venue_name}, #{area_display_name(event.area)}, Bangalore")
        else
          URI.encode("#{event.venue_name}, Bangalore")
        end
        "https://www.google.com/maps/dir/?api=1&destination=#{destination}"
      
      # Final fallback - shouldn't happen if UI conditional is correct
      true ->
        "https://www.google.com/maps/search/#{URI.encode("Bangalore")}"
    end
  end

  defp area_display_name(area) do
    area
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end