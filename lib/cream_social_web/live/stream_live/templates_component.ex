defmodule CreamSocialWeb.StreamLive.TemplatesComponent do
  use CreamSocialWeb, :live_component
  require Logger
  alias CreamSocial.ContentGenerator

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow dark:shadow-gray-900/20 p-4 mb-4">
      <!-- Header -->
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
          <svg class="w-5 h-5 mr-2 text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
          AI Post Generator
        </h3>
        <button
          phx-click="toggle_templates"
          phx-target={@myself}
          class="text-sm text-indigo-600 hover:text-indigo-800 dark:text-indigo-400 dark:hover:text-indigo-200"
        >
          <%= if @show_templates do %>
            Hide Templates
          <% else %>
            Show Templates
          <% end %>
        </button>
      </div>

      <%= if @show_templates do %>
        <!-- Daily Suggestion Test -->
        <div class="mb-4 p-3 bg-orange-50 dark:bg-orange-900/20 border border-orange-200 dark:border-orange-700 rounded-lg">
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <h4 class="text-sm font-medium text-orange-800 dark:text-orange-200 mb-1">
                📅 Today's Suggestion
              </h4>
              <p class="text-sm text-orange-700 dark:text-orange-300">
                <%= if @daily_suggestion do %>
                  <%= @daily_suggestion.icon %> <%= @daily_suggestion.name %>
                <% else %>
                  Loading suggestion...
                <% end %>
              </p>
            </div>
            <button
              phx-click="generate_from_suggestion"
              phx-target={@myself}
              class="px-3 py-1 bg-orange-500 text-white text-xs rounded-md hover:bg-orange-600 transition-colors"
              disabled={@generating}
            >
              Generate
            </button>
          </div>
        </div>

        <!-- Category Tabs -->
        <div class="mb-4">
          <div class="flex flex-wrap gap-2">
            <%= for category <- @categories do %>
              <button
                phx-click="select_category"
                phx-value-category={category}
                phx-target={@myself}
                class={[
                  "px-3 py-1 text-xs rounded-full transition-colors",
                  if(@selected_category == category, 
                    do: "bg-blue-500 text-white", 
                    else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
                  )
                ]}
              >
                <%= ContentGenerator.get_category_icon(category) %> <%= String.replace(category, "_", " ") |> String.capitalize() %>
              </button>
            <% end %>
          </div>
        </div>

        <!-- Templates Grid -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-4">
          <%= for {key, template} <- @filtered_templates do %>
            <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-3 hover:border-blue-300 dark:hover:border-blue-600 transition-colors">
              <div class="flex items-start justify-between mb-2">
                <div class="flex items-center">
                  <span class="text-lg mr-2"><%= template.icon %></span>
                  <h5 class="text-sm font-medium text-gray-900 dark:text-white"><%= template.name %></h5>
                </div>
                <button
                  phx-click="generate_from_template"
                  phx-value-template={key}
                  phx-target={@myself}
                  class="px-2 py-1 bg-blue-500 text-white text-xs rounded hover:bg-blue-600 transition-colors"
                  disabled={@generating}
                >
                  Generate
                </button>
              </div>
              <p class="text-xs text-gray-600 dark:text-gray-400 line-clamp-2">
                <%= String.slice(template.prompt, 0, 100) %><%= if String.length(template.prompt) > 100, do: "..." %>
              </p>
            </div>
          <% end %>
        </div>

        <!-- Trending Topics -->
        <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
          <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-2 flex items-center">
            🔥 Trending in Bangalore
            <span class="ml-2 text-xs text-gray-500 font-normal">Click to generate posts</span>
          </h4>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
            <%= for topic_data <- Enum.take(@trending_data, 6) do %>
              <button
                phx-click="generate_from_trending"
                phx-value-topic={topic_data.topic}
                phx-value-hashtag={topic_data.hashtag}
                phx-target={@myself}
                class="flex items-center justify-between p-2 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg text-left hover:bg-red-100 dark:hover:bg-red-900/30 transition-colors group"
                disabled={@generating}
              >
                <div class="flex-1 min-w-0">
                  <div class="flex items-center space-x-2">
                    <span class="text-sm font-medium text-red-700 dark:text-red-300 truncate">
                      <%= topic_data.hashtag %>
                    </span>
                    <span class="text-xs bg-red-200 dark:bg-red-800 text-red-800 dark:text-red-200 px-1 py-0.5 rounded">
                      <%= topic_data.category %>
                    </span>
                  </div>
                  <p class="text-xs text-red-600 dark:text-red-400 truncate mt-1">
                    <%= topic_data.topic %>
                  </p>
                </div>
                <div class="flex items-center space-x-1 ml-2">
                  <span class="text-xs text-red-500 dark:text-red-400">
                    <%= topic_data.score %>
                  </span>
                  <svg class="w-3 h-3 text-red-500 dark:text-red-400 group-hover:text-red-600 dark:group-hover:text-red-300 transition-colors" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M12.395 2.553a1 1 0 00-1.45-.385c-.345.23-.614.558-.822.88-.214.33-.403.713-.57 1.116-.334.804-.614 1.768-.84 2.734a31.365 31.365 0 00-.613 3.58 2.64 2.64 0 01-.945-1.067c-.328-.68-.398-1.534-.398-2.654A1 1 0 005.05 6.05 6.981 6.981 0 003 11a7 7 0 1011.95-4.95c-.592-.591-.98-.985-1.348-1.467-.363-.476-.724-1.063-1.207-2.03zM12.12 15.12A3 3 0 017 13s.879.5 2.5.5c0-1 .5-4 1.25-4.5.5 1 .786 1.293 1.371 1.879A2.99 2.99 0 0113 13a2.99 2.99 0 01-.879 2.121z" clip-rule="evenodd"></path>
                  </svg>
                </div>
              </button>
            <% end %>
          </div>
        </div>
        
        <%= if @error do %>
          <div class="mt-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg">
            <p class="text-sm text-red-700 dark:text-red-300"><%= @error %></p>
          </div>
        <% end %>
        
        <%= if @generating do %>
          <div class="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-700 rounded-lg">
            <div class="flex items-center">
              <svg class="animate-spin w-4 h-4 mr-2 text-blue-500" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <span class="text-sm text-blue-700 dark:text-blue-300">Generating your Bangalore-flavored post...</span>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    try do
      templates = ContentGenerator.get_templates()
      categories = templates |> Map.values() |> Enum.map(& &1.category) |> Enum.uniq()
      daily_suggestion = ContentGenerator.suggest_daily_prompt()
      trending_topics = ContentGenerator.get_trending_topics()
      
      # Get full trending data from database
      trending_data = try do
        CreamSocial.Trending.get_trending_hashtags(limit: 8)
      rescue
        _error -> []
      end

      socket = 
        socket
        |> assign(:show_templates, false)
        |> assign(:templates, templates)
        |> assign(:categories, categories)
        |> assign(:selected_category, "daily_life")
        |> assign(:filtered_templates, ContentGenerator.get_templates_by_category("daily_life"))
        |> assign(:daily_suggestion, daily_suggestion)
        |> assign(:trending_topics, trending_topics)
        |> assign(:trending_data, trending_data)
        |> assign(:generating, false)
        |> assign(:error, nil)

      {:ok, socket}
    rescue
      error ->
        Logger.error("Templates component mount failed: #{inspect(error)}")
        
        # Fallback to minimal state
        socket = 
          socket
          |> assign(:show_templates, false)
          |> assign(:templates, %{})
          |> assign(:categories, [])
          |> assign(:selected_category, "daily_life")
          |> assign(:filtered_templates, %{})
          |> assign(:daily_suggestion, %{name: "Error", icon: "❌"})
          |> assign(:trending_topics, [])
          |> assign(:trending_data, [])
          |> assign(:generating, false)
          |> assign(:error, "Failed to load templates")

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("toggle_templates", _params, socket) do
    {:noreply, assign(socket, :show_templates, !socket.assigns.show_templates)}
  end

  def handle_event("generate_from_suggestion", _params, socket) do
    # Find the template key for the daily suggestion
    daily_template = socket.assigns.daily_suggestion
    template_key = socket.assigns.templates
    |> Enum.find_value(fn {key, template} -> 
      if template.name == daily_template.name, do: key, else: nil
    end)
    
    if template_key do
      socket = assign(socket, :generating, true)
      socket = assign(socket, :error, nil)
      send(self(), {:generate_post_from_template, template_key, socket.assigns.myself})
      {:noreply, socket}
    else
      {:noreply, assign(socket, :error, "Could not find template for daily suggestion")}
    end
  end

  def handle_event("generate_from_template", %{"template" => template_key}, socket) do
    socket = assign(socket, :generating, true)
    socket = assign(socket, :error, nil)
    send(self(), {:generate_post_from_template, template_key, socket.assigns.myself})
    {:noreply, socket}
  end

  def handle_event("generate_from_topic", %{"topic" => topic}, socket) do
    socket = assign(socket, :generating, true)
    socket = assign(socket, :error, nil)
    send(self(), {:generate_post_from_topic, topic, socket.assigns.myself})
    {:noreply, socket}
  end

  def handle_event("select_category", %{"category" => category}, socket) do
    filtered_templates = ContentGenerator.get_templates_by_category(category)
    
    socket = 
      socket
      |> assign(:selected_category, category)
      |> assign(:filtered_templates, filtered_templates)
    
    {:noreply, socket}
  end

  def handle_event("generate_from_template", %{"template" => template_key}, socket) do
    socket = assign(socket, :generating, true)
    socket = assign(socket, :error, nil)
    send(self(), {:generate_post_from_template, template_key, socket.assigns.myself})
    {:noreply, socket}
  end

  def handle_event("generate_from_suggestion", _params, socket) do
    # Find the template key for the daily suggestion
    daily_template = socket.assigns.daily_suggestion
    template_key = socket.assigns.templates
    |> Enum.find_value(fn {key, template} -> 
      if template.name == daily_template.name, do: key, else: nil
    end)
    
    if template_key do
      socket = assign(socket, :generating, true)
      socket = assign(socket, :error, nil)
      send(self(), {:generate_post_from_template, template_key, socket.assigns.myself})
      {:noreply, socket}
    else
      {:noreply, assign(socket, :error, "Could not find template for daily suggestion")}
    end
  end

  def handle_event("generate_from_topic", %{"topic" => topic}, socket) do
    socket = assign(socket, :generating, true)
    socket = assign(socket, :error, nil)
    send(self(), {:generate_post_from_topic, topic, socket.assigns.myself})
    {:noreply, socket}
  end

  def handle_event("generate_from_trending", %{"topic" => topic, "hashtag" => hashtag}, socket) do
    require Logger
    Logger.info("Generate from trending: topic=#{topic}, hashtag=#{hashtag}, component_id=#{inspect(socket.assigns.myself)}")
    
    socket = assign(socket, :generating, true)
    socket = assign(socket, :error, nil)
    send(self(), {:generate_post_from_trending, topic, hashtag, socket.assigns.myself})
    {:noreply, socket}
  end

  @impl true  
  def update(%{action: :generation_complete}, socket) do
    socket = 
      socket
      |> assign(:generating, false)
      |> assign(:error, nil)
    
    {:ok, socket}
  end

  def update(%{action: {:generation_failed, error}}, socket) do
    socket = 
      socket
      |> assign(:generating, false)
      |> assign(:error, error)
    
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end