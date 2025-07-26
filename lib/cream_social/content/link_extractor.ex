defmodule CreamSocial.Content.LinkExtractor do
  @moduledoc """
  Service for extracting link previews from URLs
  """
  
  alias CreamSocial.Content.LinkPreview
  alias CreamSocial.Repo
  import Ecto.Query
  
  @timeout 10_000
  @user_agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  
  def extract_and_cache(url) do
    case get_cached_preview(url) do
      nil -> 
        fetch_and_cache(url)
      preview -> 
        {:ok, preview}
    end
  end
  
  def extract_links_from_text(text) do
    # Match URLs properly - using a more specific pattern for HTTP/HTTPS URLs
    ~r/https?:\/\/[^\s\t\n\r\f\v<>"'{}|\\^`\[\]]+/u
    |> Regex.scan(text)
    |> Enum.map(&List.first/1)
    |> Enum.map(&String.trim_trailing(&1, ".,;:!?)]}"))
    |> Enum.filter(fn url -> String.length(url) > 10 end)  # Filter out very short matches
    |> Enum.uniq()
  end
  
  defp get_cached_preview(url) do
    # Check if we have a cached preview that's less than 24 hours old
    twenty_four_hours_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(-24 * 60 * 60)
    
    Repo.one(
      from lp in LinkPreview,
      where: lp.url == ^url and lp.cached_at > ^twenty_four_hours_ago
    )
  end
  
  defp fetch_and_cache(url) do
    with {:ok, response} <- fetch_url(url),
         {:ok, metadata} <- parse_metadata(response.body) do
      
      preview_attrs = Map.put(metadata, :url, url)
      |> Map.put(:cached_at, NaiveDateTime.utc_now())
      
      case create_or_update_preview(url, preview_attrs) do
        {:ok, preview} -> 
          {:ok, preview}
        {:error, _reason} -> 
          {:error, "Failed to cache preview"}
      end
    else
      error -> 
        error
    end
  end
  
  defp fetch_url(url) do
    headers = [
      {"User-Agent", @user_agent},
      {"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
      {"Accept-Language", "en-US,en;q=0.5"},
      {"Accept-Encoding", "gzip, deflate"},
      {"Connection", "keep-alive"}
    ]
    
    options = [
      timeout: @timeout, 
      recv_timeout: @timeout,
      follow_redirect: true,
      max_redirect: 5
    ]
    
    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, %{body: body}}
      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "HTTP #{code}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end
  
  defp parse_metadata(html) do
    # Parse HTML to extract Open Graph and meta tags
    case Floki.parse_document(html) do
      {:ok, document} ->
        metadata = %{
          title: extract_title(document),
          description: extract_description(document), 
          image_url: extract_image(document),
          site_name: extract_site_name(document)
        }
        
        {:ok, metadata}
      error ->
        {:error, "Failed to parse HTML: #{inspect(error)}"}
    end
  rescue
    e -> {:error, "Failed to parse HTML: #{inspect(e)}"}
  end
  
  defp extract_title(document) do
    # Try Open Graph title first, then regular title
    case Floki.find(document, "meta[property='og:title']") |> Floki.attribute("content") |> List.first() do
      nil -> 
        case Floki.find(document, "title") |> Floki.text() |> String.trim() do
          "" -> nil
          title -> title
        end
      og_title -> og_title
    end
  end
  
  defp extract_description(document) do
    # Try Open Graph description first, then meta description
    case Floki.find(document, "meta[property='og:description']") |> Floki.attribute("content") |> List.first() do
      nil -> 
        Floki.find(document, "meta[name='description']") |> Floki.attribute("content") |> List.first()
      og_desc -> og_desc
    end
  end
  
  defp extract_image(document) do
    # Try Open Graph image first, then Twitter card image
    case Floki.find(document, "meta[property='og:image']") |> Floki.attribute("content") |> List.first() do
      nil -> 
        Floki.find(document, "meta[name='twitter:image']") |> Floki.attribute("content") |> List.first()
      og_image -> og_image
    end
  end
  
  defp extract_site_name(document) do
    # Try Open Graph site name first
    Floki.find(document, "meta[property='og:site_name']")
    |> Floki.attribute("content")
    |> List.first()
  end
  
  defp create_or_update_preview(url, attrs) do
    case Repo.get_by(LinkPreview, url: url) do
      nil ->
        %LinkPreview{}
        |> LinkPreview.changeset(attrs)
        |> Repo.insert()
      
      existing ->
        existing
        |> LinkPreview.changeset(attrs)
        |> Repo.update()
    end
  end
end