defmodule CreamSocial.ViralPredictor do
  @moduledoc """
  AI-powered viral score prediction for social media posts.
  Analyzes content and provides engagement likelihood with Bangalore-specific factors.
  """

  require Logger

  # Bangalore-specific keywords that boost viral potential
  @bangalore_keywords %{
    # Traffic & Transportation
    "traffic" => 8, "silk board" => 12, "electronic city" => 10, "namma metro" => 15,
    "outer ring road" => 8, "hosur road" => 6, "whitefield" => 8, "koramangala" => 10,
    "indiranagar" => 8, "malleswaram" => 6, "jayanagar" => 6, "banashankari" => 6,
    
    # Tech & Startups  
    "startup" => 8, "bengaluru" => 12, "bangalore" => 10, "tech" => 6, "coding" => 5,
    "developer" => 5, "software" => 4, "IT" => 4, "work from home" => 8, "wfh" => 6,
    "office" => 4, "meeting" => 3, "code" => 4,
    
    # Sports & Entertainment
    "rcb" => 20, "royal challengers" => 18, "virat kohli" => 15, "ipl" => 12,
    "cricket" => 8, "match" => 6, "chinnaswamy" => 12, "ee sala cup namde" => 25,
    
    # Food & Culture
    "masala dosa" => 10, "filter coffee" => 8, "idli" => 6, "vada" => 4, "darshini" => 8,
    "ctr" => 10, "vidyarthi bhavan" => 8, "mangalore" => 6, "udupi" => 6,
    "kannada" => 8, "karnataka" => 6, "ugadi" => 8, "ganesh chaturthi" => 8,
    
    # Weather & Lifestyle
    "weather" => 6, "rain" => 8, "pleasant" => 4, "climate" => 4, "monsoon" => 6,
    "pub" => 6, "brewery" => 8, "weekend" => 4, "cubbon park" => 6, "lalbagh" => 6,
    "commercial street" => 6, "brigade road" => 6, "mg road" => 6,
    
    # Local Slang & Expressions
    "maccha" => 10, "guru" => 8, "swalpa" => 6, "adjust" => 8, "one minute" => 6,
    "full" => 4, "scene" => 4, "bere" => 6, "howdu" => 8
  }

  # High-engagement content patterns (defined as function to avoid compilation issues)
  defp get_viral_patterns do
    %{
      # Questions increase engagement
      ~r/\?/ => 5,
      # Numbers and lists
      ~r/\d+/ => 3,
      # Hashtags
      ~r/#\w+/ => 4,
      # Mentions
      ~r/@\w+/ => 3,
      # Emojis
      ~r/[\x{1F600}-\x{1F64F}]|[\x{1F300}-\x{1F5FF}]|[\x{1F680}-\x{1F6FF}]|[\x{2600}-\x{26FF}]|[\x{2700}-\x{27BF}]/u => 2,
      # ALL CAPS (excitement/emphasis)
      ~r/[A-Z]{3,}/ => 6,
      # Time references
      ~r/\b(today|tomorrow|yesterday|now|tonight|morning|evening)\b/i => 4,
      # Local time expressions
      ~r/\b(aaj|kal|abhi|subah|sham)\b/i => 6
    }
  end

  # Content length optimization
  @optimal_length_range 50..280

  # Time-based multipliers (IST)
  @time_multipliers %{
    # Morning commute
    6..10 => 1.2,
    # Lunch break  
    12..14 => 1.1,
    # Evening commute
    17..20 => 1.3,
    # Prime social time
    20..23 => 1.4,
    # Late night
    23..24 => 0.8,
    0..6 => 0.6
  }

  def calculate_viral_score(content, user_data \\ %{}, context \\ %{}) do
    base_score = analyze_content(content)
    bangalore_bonus = calculate_bangalore_factor(content)
    pattern_bonus = calculate_pattern_score(content)
    length_score = calculate_length_score(content)
    time_bonus = calculate_time_bonus()
    user_bonus = calculate_user_factor(user_data)
    
    total_score = base_score + bangalore_bonus + pattern_bonus + length_score + time_bonus + user_bonus
    
    # Cap at 100 and ensure minimum of 1
    final_score = min(100, max(1, round(total_score)))
    
    %{
      score: final_score,
      breakdown: %{
        base_content: round(base_score),
        bangalore_relevance: round(bangalore_bonus),
        engagement_patterns: round(pattern_bonus), 
        content_length: round(length_score),
        timing_bonus: round(time_bonus),
        user_influence: round(user_bonus)
      },
      suggestions: generate_suggestions(content, final_score)
    }
  end

  def suggest_improvements(content, current_score) do
    suggestions = []
    
    suggestions = if current_score < 30 do
      ["Try adding Bangalore-specific references like areas, food, or local culture" | suggestions]
    else
      suggestions
    end

    suggestions = if !String.contains?(content, "#") do
      ["Add relevant hashtags like #Bangalore #BengaluruLife #Namma" | suggestions]
    else
      suggestions
    end

    suggestions = if String.length(content) < 50 do
      ["Add more details to make your post more engaging" | suggestions]
    else
      suggestions
    end

    suggestions = if !Regex.match?(~r/\?/, content) do
      ["Consider asking a question to boost engagement" | suggestions]
    else
      suggestions
    end

    suggestions = if !Regex.match?(~r/[\x{1F600}-\x{1F64F}]|[\x{1F300}-\x{1F5FF}]|[\x{1F680}-\x{1F6FF}]|[\x{2600}-\x{26FF}]|[\x{2700}-\x{27BF}]/u, content) do
      ["Add emojis to make your post more expressive" | suggestions]
    else
      suggestions
    end

    suggestions = case get_current_ist_hour() do
      hour when hour in 6..10 ->
        ["Perfect timing for morning commute content!" | suggestions]
      hour when hour in 17..20 ->
        ["Great time for evening posts - people are active!" | suggestions]
      hour when hour in 20..23 ->
        ["Prime social media time - excellent for engagement!" | suggestions]
      _ ->
        ["Consider posting during peak hours (7-10 AM, 6-11 PM) for better reach" | suggestions]
    end

    Enum.take(suggestions, 3)
  end

  defp analyze_content(content) when is_binary(content) do
    # Base score calculation
    word_count = content |> String.split() |> length()
    
    # Basic engagement factors
    base = case word_count do
      count when count < 5 -> 10
      count when count <= 15 -> 25
      count when count <= 30 -> 35
      count when count <= 50 -> 30
      _ -> 20
    end

    # Adjust for content quality indicators
    base = if String.contains?(String.downcase(content), ["amazing", "awesome", "incredible", "unbelievable"]) do
      base + 5
    else
      base
    end

    base
  end

  defp analyze_content(_), do: 0

  defp calculate_bangalore_factor(content) do
    content_lower = String.downcase(content)
    
    @bangalore_keywords
    |> Enum.reduce(0, fn {keyword, score}, acc ->
      if String.contains?(content_lower, keyword) do
        acc + score
      else
        acc
      end
    end)
    |> min(25) # Cap bangalore bonus at 25 points
  end

  defp calculate_pattern_score(content) do
    get_viral_patterns()
    |> Enum.reduce(0, fn {pattern, score}, acc ->
      matches = Regex.scan(pattern, content) |> length()
      acc + (matches * score)
    end)
    |> min(20) # Cap pattern bonus at 20 points
  end

  defp calculate_length_score(content) do
    length = String.length(content)
    
    cond do
      length in @optimal_length_range -> 10
      length < 50 -> max(0, length / 5)
      length > 280 -> max(0, 10 - ((length - 280) / 20))
      true -> 5
    end
  end

  defp calculate_time_bonus do
    current_hour = get_current_ist_hour()
    
    @time_multipliers
    |> Enum.find_value(fn {range, multiplier} ->
      if current_hour in range, do: (multiplier - 1.0) * 10, else: nil
    end) || 0
  end

  defp calculate_user_factor(user_data) do
    # Placeholder for user influence factors
    base_influence = Map.get(user_data, :follower_count, 0) / 100
    engagement_rate = Map.get(user_data, :avg_engagement_rate, 0.05)
    
    min(10, base_influence + (engagement_rate * 100))
  end

  defp generate_suggestions(content, score) do
    cond do
      score >= 80 -> ["🔥 Excellent! This post has high viral potential"]
      score >= 60 -> ["✨ Good content! A few tweaks could make it even better"]
      score >= 40 -> ["👍 Decent post. Consider adding local Bangalore references"]
      score >= 20 -> ["📝 Needs improvement. Try adding hashtags and local context"]
      true -> ["🚀 Start fresh! Focus on Bangalore-specific content and engagement"]
    end
  end

  defp get_current_ist_hour do
    # Convert UTC to IST (UTC + 5:30)
    utc_now = DateTime.utc_now()
    ist_hour = rem(utc_now.hour + 5, 24) + if utc_now.minute >= 30, do: 1, else: 0
    min(23, ist_hour)
  end

  def get_optimal_posting_times do
    current_hour = get_current_ist_hour()
    
    base_times = [
      %{time: "7:00-9:00 AM", reason: "Morning commute peak", score: 85},
      %{time: "12:00-1:00 PM", reason: "Lunch break engagement", score: 75},
      %{time: "6:00-8:00 PM", reason: "Evening commute & leisure", score: 90},
      %{time: "8:00-11:00 PM", reason: "Prime social media time", score: 95}
    ]

    # Highlight current time if it's optimal
    Enum.map(base_times, fn time_slot ->
      case time_slot.time do
        "7:00-9:00 AM" when current_hour in 7..9 -> 
          Map.put(time_slot, :current, true)
        "12:00-1:00 PM" when current_hour in 12..13 -> 
          Map.put(time_slot, :current, true)
        "6:00-8:00 PM" when current_hour in 18..20 -> 
          Map.put(time_slot, :current, true)
        "8:00-11:00 PM" when current_hour in 20..23 -> 
          Map.put(time_slot, :current, true)
        _ -> 
          Map.put(time_slot, :current, false)
      end
    end)
  end

  def analyze_viral_elements(content) do
    elements = []
    
    # Check for local references
    if calculate_bangalore_factor(content) > 0 do
      elements = ["🏙️ Local Bangalore reference" | elements]
    end

    # Check for questions
    if Regex.match?(~r/\?/, content) do
      elements = ["❓ Engaging question" | elements]
    end

    # Check for hashtags
    hashtag_count = Regex.scan(~r/#\w+/, content) |> length()
    if hashtag_count > 0 do
      elements = ["🏷️ #{hashtag_count} hashtag(s)" | elements]
    end

    # Check for emojis
    emoji_count = Regex.scan(~r/[\x{1F600}-\x{1F64F}]|[\x{1F300}-\x{1F5FF}]|[\x{1F680}-\x{1F6FF}]|[\x{2600}-\x{26FF}]|[\x{2700}-\x{27BF}]/u, content) |> length()
    if emoji_count > 0 do
      elements = ["😊 #{emoji_count} emoji(s)" | elements]
    end

    # Check for timing
    current_hour = get_current_ist_hour()
    if current_hour in [7, 8, 9, 18, 19, 20, 21, 22] do
      elements = ["⏰ Posted at optimal time" | elements]
    end

    elements
  end
end