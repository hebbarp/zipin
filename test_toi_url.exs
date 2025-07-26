Mix.install([
  {:httpoison, "~> 2.0"},
  {:floki, ">= 0.30.0"}
])

defmodule TestToiUrl do
  def test_extraction() do
    url = "https://timesofindia.indiatimes.com/sports/cricket/india-tour-of-england/ind-vs-eng-going-for-wickets-is-a-lie-r-ashwin-urges-india-to-contain-englands-bazball-in-second-test/articleshow/122194626.cms"
    
    IO.puts("Testing Times of India URL:")
    IO.puts("URL length: #{String.length(url)}")
    IO.puts("URL: #{url}")
    
    headers = [
      {"User-Agent", "CreamSocial/1.0 (+https://creamsocial.com)"},
      {"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"}
    ]
    
    IO.puts("\n=== Testing Web Fetch ===")
    case HTTPoison.get(url, headers, [timeout: 15_000, recv_timeout: 15_000]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts("✅ Successfully fetched #{String.length(body)} characters")
        
        case Floki.parse_document(body) do
          {:ok, document} ->
            IO.puts("✅ HTML parsing successful")
            
            # Test metadata extraction
            og_title = Floki.find(document, "meta[property='og:title']")
            |> Floki.attribute("content")
            |> List.first()
            
            og_desc = Floki.find(document, "meta[property='og:description']")
            |> Floki.attribute("content")
            |> List.first()
            
            og_image = Floki.find(document, "meta[property='og:image']")
            |> Floki.attribute("content")
            |> List.first()
            
            og_site = Floki.find(document, "meta[property='og:site_name']")
            |> Floki.attribute("content")
            |> List.first()
            
            IO.puts("\n=== Extraction Results ===")
            IO.puts("Title: #{inspect(og_title)}")
            IO.puts("Description: #{inspect(og_desc)}")
            IO.puts("Image: #{inspect(og_image)}")
            IO.puts("Site: #{inspect(og_site)}")
            
          error ->
            IO.puts("❌ HTML parsing failed: #{inspect(error)}")
        end
        
      {:ok, %HTTPoison.Response{status_code: code}} ->
        IO.puts("❌ HTTP error: #{code}")
        
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("❌ Request failed: #{inspect(reason)}")
        
      error ->
        IO.puts("❌ Unknown error: #{inspect(error)}")
    end
  end
end

TestToiUrl.test_extraction()