defmodule CreamSocial.AIEnhancer do
  @moduledoc """
  Service for enhancing messages using OpenAI API.
  Takes user input and transforms it into a more polished, nuanced message with appropriate emojis.
  """

  require Logger

  @api_base Application.compile_env(:cream_social, [:openai, :api_base], "https://api.openai.com/v1")
  
  def enhance_message(text, user) when is_binary(text) and byte_size(text) > 0 do
    api_key = get_api_key(user)
    
    case api_key do
      nil -> 
        {:error, "OpenAI API key not configured. Please add your API key in Settings → Profile to enable AI enhancement."}
      key -> 
        # Detect language for conservative enhancement
        language = detect_language(text)
        make_enhancement_request(text, key, language)
    end
  end
  
  def enhance_message(_, _), do: {:error, "Invalid input text"}

  defp detect_language(text) do
    cond do
      # Check for Kannada script (Unicode range U+0C80–U+0CFF)
      String.contains?(text, ["ಅ", "ಆ", "ಇ", "ಈ", "ಉ", "ಊ", "ಎ", "ಏ", "ಐ", "ಒ", "ಓ", "ಔ", "ಕ", "ಖ", "ಗ", "ಘ", "ಙ", "ಚ", "ಛ", "ಜ", "ಝ", "ಞ", "ಟ", "ಠ", "ಡ", "ಢ", "ಣ", "ತ", "ಥ", "ದ", "ಧ", "ನ", "ಪ", "ಫ", "ಬ", "ಭ", "ಮ", "ಯ", "ರ", "ಲ", "ವ", "ಶ", "ಷ", "ಸ", "ಹ", "ಳ", "ೞ", "ೱ", "ೲ"]) -> :kannada
      # Check for Devanagari script (Hindi) - common characters
      String.contains?(text, ["अ", "आ", "इ", "ई", "उ", "ऊ", "ए", "ऐ", "ओ", "औ", "क", "ख", "ग", "घ", "ङ", "च", "छ", "ज", "झ", "ञ", "ट", "ठ", "ड", "ढ", "ण", "त", "थ", "द", "ध", "न", "प", "फ", "ब", "भ", "म", "य", "र", "ल", "व", "श", "ष", "स", "ह"]) -> :hindi
      # Default to English
      true -> :english
    end
  end

  defp get_api_key(user) do
    # First try to get user's personal API key
    case user do
      %{openai_api_key: key} when is_binary(key) and byte_size(key) > 0 ->
        key
      _ ->
        # Fallback to system API key if user hasn't set one
        Application.get_env(:cream_social, :openai)[:api_key] ||
          System.get_env("OPENAI_API_KEY")
    end
  end

  defp make_enhancement_request(text, api_key, _language \\ :english) do
    url = "#{@api_base}/chat/completions"
    
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{api_key}"}
    ]
    
    body = %{
      "model" => "gpt-4o-mini",
      "messages" => [
        %{
          "role" => "system",
          "content" => english_system_prompt()
        },
        %{
          "role" => "user", 
          "content" => text
        }
      ],
      "max_tokens" => 500,
      "temperature" => 0.7
    }
    
    json_body = Jason.encode!(body)
    
    case HTTPoison.post(url, json_body, headers, recv_timeout: 30_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        parse_openai_response(response_body)
      
      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        Logger.error("OpenAI API error: #{status_code} - #{error_body}")
        {:error, "AI service temporarily unavailable (#{status_code})"}
      
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, "Connection to AI service failed"}
    end
  end

  defp english_system_prompt do
    """
    You are a social media writing assistant. Your job is to take user input and transform it into a more polished, engaging social media post while maintaining the user's original intent and voice.

    Guidelines:
    1. Keep the core message and meaning intact
    2. Make the text more engaging and well-structured
    3. Add relevant emojis where appropriate (but don't overuse them)
    4. Fix grammar and spelling errors
    5. Improve readability with better formatting
    6. Keep it authentic - don't make it sound overly corporate or fake
    7. Maintain appropriate tone for social media
    8. If the original text is already well-written, make minimal changes
    9. Keep responses under 280 characters when possible for social media compatibility
    10. Add line breaks for better readability when needed

    Return only the enhanced text, nothing else. Do not include any explanations or meta-commentary.
    """
  end

  defp hindi_system_prompt do
    """
    आप एक सोशल मीडिया लेखन सहायक हैं। आपका काम उपयोगकर्ता के मूल संदेश और स्वर को बनाए रखते हुए उसे बेहतर बनाना है।

    दिशा-निर्देश:
    1. मूल संदेश और अर्थ को बिल्कुल वैसा ही रखें
    2. केवल व्याकरण और वर्तनी की त्रुटियों को ठीक करें
    3. बहुत कम या कोई इमोजी न जोड़ें (केवल अगर बिल्कुल उपयुक्त हो)
    4. भारतीय संस्कृति और संदर्भ का सम्मान करें
    5. अगर पाठ पहले से ही अच्छा है, तो बहुत कम बदलाव करें
    6. प्राकृतिक और प्रामाणिक रखें
    7. पाश्चात्य शैली या अनुचित भाषा न जोड़ें

    केवल सुधारा गया पाठ वापस करें, कोई व्याख्या नहीं।
    """
  end

  defp kannada_system_prompt do
    """
    ನೀವು ಒಂದು ಸಾಮಾಜಿಕ ಮಾಧ್ಯಮ ಬರವಣಿಗೆ ಸಹಾಯಕರು. ಬಳಕೆದಾರರ ಮೂಲ ಸಂದೇಶ ಮತ್ತು ಸ್ವರವನ್ನು ಕಾಪಾಡುತ್ತಾ ಅದನ್ನು ಸುಧಾರಿಸುವುದು ನಿಮ್ಮ ಕೆಲಸ.

    ಮಾರ್ಗದರ್ಶನಗಳು:
    1. ಮೂಲ ಸಂದೇಶ ಮತ್ತು ಅರ್ಥವನ್ನು ಹಾಗೆಯೇ ಇರಿಸಿ
    2. ಕೇವಲ ವ್ಯಾಕರಣ ಮತ್ತು ಕಾಗುಣಿತ ದೋಷಗಳನ್ನು ಸರಿಪಡಿಸಿ
    3. ಬಹಳ ಕಡಿಮೆ ಅಥವಾ ಯಾವುದೇ ಇಮೋಜಿ ಸೇರಿಸಬೇಡಿ
    4. ಕನ್ನಡ ಸಂಸ್ಕೃತಿ ಮತ್ತು ಸಂದರ್ಭವನ್ನು ಗೌರವಿಸಿ
    5. ಪಠ್ಯ ಈಗಾಗಲೇ ಚೆನ್ನಾಗಿದ್ದರೆ, ಬಹಳ ಕಡಿಮೆ ಬದಲಾವಣೆ ಮಾಡಿ
    6. ನೈಸರ್ಗಿಕ ಮತ್ತು ಪ್ರಾಮಾಣಿಕವಾಗಿ ಇರಿಸಿ
    7. ಪಾಶ್ಚಾತ್ಯ ಶೈಲಿ ಅಥವಾ ಅನುಚಿತ ಭಾಷೆ ಸೇರಿಸಬೇಡಿ

    ಕೇವಲ ಸುಧಾರಿಸಿದ ಪಠ್ಯವನ್ನು ಹಿಂತಿರುಗಿಸಿ, ಯಾವುದೇ ವಿವರಣೆ ಬೇಡ.
    """
  end

  defp parse_openai_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"choices" => [%{"message" => %{"content" => content}} | _]}} ->
        enhanced_text = String.trim(content)
        {:ok, enhanced_text}
      
      {:ok, %{"error" => %{"message" => error_message}}} ->
        Logger.error("OpenAI API error: #{error_message}")
        {:error, "AI enhancement failed: #{error_message}"}
      
      {:ok, unexpected} ->
        Logger.error("Unexpected OpenAI response structure: #{inspect(unexpected)}")
        {:error, "Unexpected response from AI service"}
      
      {:error, decode_error} ->
        Logger.error("Failed to decode OpenAI response: #{inspect(decode_error)}")
        {:error, "Failed to process AI response"}
    end
  end
end