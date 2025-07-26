defmodule CreamSocial.ContentGenerator do
  @moduledoc """
  AI-powered content generation with Bangalore-specific templates and local context.
  Helps users create engaging posts with pre-built templates and trending topic suggestions.
  """

  require Logger
  alias CreamSocial.AIEnhancer

  @bangalore_templates %{
    "traffic" => %{
      name: "Traffic & Commute",
      prompt: "Write about your Bangalore traffic or commute experience today. Include specific areas like Silk Board, Electronic City, or mention Namma Metro if relevant. Keep it relatable and add some humor if appropriate.",
      icon: "🚗",
      category: "daily_life"
    },
    "weather" => %{
      name: "Weather Update",
      prompt: "React to today's Bangalore weather. Mention if it's the usual pleasant climate, unexpected rain, or summer heat. Make it conversational and relatable to fellow Bangaloreans.",
      icon: "🌤️",
      category: "daily_life"
    },
    "food" => %{
      name: "Food Recommendation",
      prompt: "Recommend a local food spot or dish in Bangalore. Could be street food, a restaurant, or homemade food. Include the area/location and why it's special. Make others crave it!",
      icon: "🍛",
      category: "lifestyle"
    },
    "rcb" => %{
      name: "RCB Cricket",
      prompt: "Share your thoughts about RCB's recent match or the cricket season. Express the typical RCB fan emotions - hope, excitement, or friendly frustration. Use local cricket slang if you know any.",
      icon: "🏏",
      category: "sports"
    },
    "startup" => %{
      name: "Tech & Startups",
      prompt: "Share thoughts about the Bangalore tech scene, startup culture, or work life. Could be about traffic to office, work-from-home, or industry trends. Keep it professional yet relatable.",
      icon: "💻",
      category: "professional"
    },
    "festival" => %{
      name: "Festival Wishes",
      prompt: "Write festival wishes or talk about cultural celebrations in Bangalore. You can write in Kannada, Hindi, or English. Include local cultural context and traditions.",
      icon: "🎉",
      category: "culture"
    },
    "weekend" => %{
      name: "Weekend Plans",
      prompt: "Share your weekend plans in Bangalore. Could be visiting Cubbon Park, going to UB City Mall, exploring local markets, or just staying home. Make it engaging for others to relate or get ideas.",
      icon: "🎯",
      category: "lifestyle"
    },
    "metro" => %{
      name: "Namma Metro",
      prompt: "Share your Namma Metro experience - new routes, convenience, crowded stations, or how it's changing your commute. Include specific metro stations if relevant.",
      icon: "🚇",
      category: "daily_life"
    }
  }

  @trending_topics [
    "Bangalore traffic updates",
    "Namma Metro new routes", 
    "RCB latest match",
    "Weather changes",
    "Local food discoveries",
    "Weekend spots in Bangalore",
    "Work from home vs office",
    "Startup scene updates",
    "Kannada festivals",
    "New restaurants opening"
  ]

  def get_templates do
    @bangalore_templates
  end

  def get_template(template_key) when is_binary(template_key) do
    Map.get(@bangalore_templates, template_key)
  end

  def get_templates_by_category(category) do
    @bangalore_templates
    |> Enum.filter(fn {_key, template} -> template.category == category end)
    |> Enum.into(%{})
  end

  def get_trending_topics do
    # Get from database with fallback to static list
    try do
      trending_hashtags = CreamSocial.Trending.get_trending_hashtags(limit: 8)
      
      if length(trending_hashtags) > 0 do
        Enum.map(trending_hashtags, & &1.topic)
      else
        # Fallback to static list if no database topics
        @trending_topics
      end
    rescue
      _error ->
        # Fallback to static list on any error
        @trending_topics
    end
  end

  def generate_post(template_key, user_context \\ %{}, user) when is_binary(template_key) do
    case get_template(template_key) do
      nil -> 
        {:error, "Template not found"}
      
      template ->
        enhanced_prompt = build_enhanced_prompt(template, user_context)
        generate_content_with_ai(enhanced_prompt, user)
    end
  end

  def suggest_daily_prompt do
    # Get a random template based on current day and time (UTC + 5:30 for IST)
    utc_now = DateTime.utc_now()
    ist_hour = rem(utc_now.hour + 5, 24) + if utc_now.minute >= 30, do: 1, else: 0
    
    template_key = case ist_hour do
      hour when hour >= 6 and hour < 10 -> 
        # Morning commute hours
        Enum.random(["traffic", "metro", "weather"])
      
      hour when hour >= 12 and hour < 14 ->
        # Lunch time
        Enum.random(["food", "startup"])
        
      hour when hour >= 17 and hour < 20 ->
        # Evening commute
        Enum.random(["traffic", "metro"])
        
      hour when hour >= 20 or hour < 6 ->
        # Evening/night
        Enum.random(["rcb", "weekend", "food"])
        
      _ ->
        # Default random
        @bangalore_templates |> Map.keys() |> Enum.random()
    end
    
    get_template(template_key)
  end

  defp build_enhanced_prompt(template, user_context) do
    base_prompt = template.prompt
    
    # Add user context if available
    context_additions = []
    
    if Map.get(user_context, :location) do
      context_additions = ["Mention #{user_context.location} area if relevant." | context_additions]
    end
    
    if Map.get(user_context, :interests) do
      context_additions = ["Consider user interests: #{Enum.join(user_context.interests, ", ")}." | context_additions]
    end
    
    # Add local context
    local_context = "Keep it authentic to Bangalore culture. Use local references naturally. Write in a conversational social media style."
    
    enhanced_prompt = [base_prompt, local_context | context_additions] |> Enum.join(" ")
    
    "Generate a social media post based on this prompt: #{enhanced_prompt}"
  end

  defp generate_content_with_ai(prompt, user) do
    # Use existing AI enhancer infrastructure with custom prompt
    case AIEnhancer.enhance_message(prompt, user) do
      {:ok, generated_content} ->
        # Clean up the generated content (remove quotes if AI added them)
        cleaned_content = generated_content
        |> String.trim()
        |> String.replace(~r/^["']/, "")
        |> String.replace(~r/["']$/, "")
        
        {:ok, cleaned_content}
        
      {:error, reason} ->
        {:error, "Content generation failed: #{reason}"}
    end
  end

  def get_category_icon(category) do
    case category do
      "daily_life" -> "🏙️"
      "lifestyle" -> "✨"
      "sports" -> "🏆"
      "professional" -> "💼"
      "culture" -> "🎭"
      _ -> "📝"
    end
  end
end