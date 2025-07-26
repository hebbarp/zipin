defmodule CreamSocialWeb.StreamLive.ViralScoreComponent do
  use CreamSocialWeb, :live_component
  alias CreamSocial.ViralPredictor

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gradient-to-r from-purple-50 to-pink-50 dark:from-purple-900/20 dark:to-pink-900/20 rounded-lg p-4 mb-4 border border-purple-200 dark:border-purple-700">
      <!-- Header -->
      <div class="flex items-center justify-between mb-3">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
          <svg class="w-5 h-5 mr-2 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
          </svg>
          Viral Score Predictor
        </h3>
        <button
          phx-click="toggle_predictor"
          phx-target={@myself}
          class="text-sm text-indigo-600 hover:text-indigo-800 dark:text-indigo-400 dark:hover:text-indigo-200"
        >
          <%= if @show_predictor do %>
            Hide Predictor
          <% else %>
            Show Predictor
          <% end %>
        </button>
      </div>

      <%= if @show_predictor do %>
        <!-- Viral Score Display -->
        <div class="mb-4">
          <div class="flex items-center justify-between mb-2">
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Viral Potential</span>
            <span class={[
              "text-lg font-bold",
              score_color_class(@viral_data.score)
            ]}>
              <%= @viral_data.score %>/100
            </span>
          </div>
          
          <!-- Progress Bar -->
          <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3 mb-2">
            <div 
              class={[
                "h-3 rounded-full transition-all duration-300",
                score_bg_class(@viral_data.score)
              ]}
              style={"width: #{@viral_data.score}%"}
            >
            </div>
          </div>
          
          <!-- Score Description -->
          <p class="text-xs text-gray-600 dark:text-gray-400">
            <%= score_description(@viral_data.score) %>
          </p>
        </div>

        <!-- Score Breakdown -->
        <div class="grid grid-cols-2 gap-2 mb-4">
          <%= for {factor, score} <- @viral_data.breakdown do %>
            <div class="bg-white dark:bg-gray-800 rounded-md p-2 border border-gray-200 dark:border-gray-600">
              <div class="flex items-center justify-between">
                <span class="text-xs text-gray-600 dark:text-gray-400">
                  <%= format_factor_name(factor) %>
                </span>
                <span class="text-xs font-medium text-gray-900 dark:text-white">
                  +<%= score %>
                </span>
              </div>
            </div>
          <% end %>
        </div>

        <!-- Suggestions -->
        <%= if length(@suggestions) > 0 do %>
          <div class="mb-4">
            <h4 class="text-sm font-medium text-gray-800 dark:text-gray-200 mb-2 flex items-center">
              💡 Suggestions to Boost Engagement
            </h4>
            <ul class="space-y-1">
              <%= for suggestion <- @suggestions do %>
                <li class="text-xs text-gray-600 dark:text-gray-400 flex items-start">
                  <span class="text-purple-500 mr-1">•</span>
                  <%= suggestion %>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>

        <!-- Viral Elements -->
        <%= if length(@viral_elements) > 0 do %>
          <div class="mb-4">
            <h4 class="text-sm font-medium text-gray-800 dark:text-gray-200 mb-2">
              ✨ Viral Elements Detected
            </h4>
            <div class="flex flex-wrap gap-1">
              <%= for element <- @viral_elements do %>
                <span class="inline-flex items-center px-2 py-1 rounded-full text-xs bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300">
                  <%= element %>
                </span>
              <% end %>
            </div>
          </div>
        <% end %>

        <!-- Optimal Posting Times -->
        <div class="border-t border-purple-200 dark:border-purple-700 pt-3">
          <h4 class="text-sm font-medium text-gray-800 dark:text-gray-200 mb-2 flex items-center">
            ⏰ Optimal Posting Times
          </h4>
          <div class="grid grid-cols-2 gap-2">
            <%= for time_slot <- @optimal_times do %>
              <div class={[
                "p-2 rounded-md text-xs border",
                if time_slot.current do
                  "bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-700 text-green-700 dark:text-green-300"
                else
                  "bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-gray-600 text-gray-600 dark:text-gray-400"
                end
              ]}>
                <div class="font-medium">
                  <%= time_slot.time %>
                  <%= if time_slot.current do %>
                    <span class="text-green-500">📍</span>
                  <% end %>
                </div>
                <div class="text-xs opacity-75"><%= time_slot.reason %></div>
                <div class="text-xs font-medium">Score: <%= time_slot.score %></div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    optimal_times = ViralPredictor.get_optimal_posting_times()
    
    socket = 
      socket
      |> assign(:show_predictor, false)
      |> assign(:viral_data, %{score: 1, breakdown: %{}, suggestions: []})
      |> assign(:suggestions, [])
      |> assign(:viral_elements, [])
      |> assign(:optimal_times, optimal_times)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_predictor", _params, socket) do
    {:noreply, assign(socket, :show_predictor, !socket.assigns.show_predictor)}
  end

  @impl true
  def update(%{content: content}, socket) when is_binary(content) do
    # Calculate viral score for the new content
    viral_data = ViralPredictor.calculate_viral_score(content)
    suggestions = ViralPredictor.suggest_improvements(content, viral_data.score)
    viral_elements = ViralPredictor.analyze_viral_elements(content)
    
    socket = 
      socket
      |> assign(:viral_data, viral_data)
      |> assign(:suggestions, suggestions)
      |> assign(:viral_elements, viral_elements)

    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  # Helper functions for styling
  defp score_color_class(score) do
    cond do
      score >= 80 -> "text-green-600 dark:text-green-400"
      score >= 60 -> "text-blue-600 dark:text-blue-400"
      score >= 40 -> "text-yellow-600 dark:text-yellow-400"
      score >= 20 -> "text-orange-600 dark:text-orange-400"
      true -> "text-red-600 dark:text-red-400"
    end
  end

  defp score_bg_class(score) do
    cond do
      score >= 80 -> "bg-green-500"
      score >= 60 -> "bg-blue-500"
      score >= 40 -> "bg-yellow-500"
      score >= 20 -> "bg-orange-500"
      true -> "bg-red-500"
    end
  end

  defp score_description(score) do
    cond do
      score >= 80 -> "🔥 Highly viral! This content has excellent engagement potential"
      score >= 60 -> "✨ Good viral potential with room for improvement"
      score >= 40 -> "👍 Moderate potential - consider adding local references"
      score >= 20 -> "📝 Low potential - needs more engaging elements"
      true -> "🚀 Very low potential - consider major improvements"
    end
  end

  defp format_factor_name(factor) do
    case factor do
      :base_content -> "Content Quality"
      :bangalore_relevance -> "Local Relevance"
      :engagement_patterns -> "Viral Patterns"
      :content_length -> "Length Score"
      :timing_bonus -> "Timing Bonus"
      :user_influence -> "User Factor"
      _ -> factor |> to_string() |> String.replace("_", " ") |> String.capitalize()
    end
  end
end