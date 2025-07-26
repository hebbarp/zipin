defmodule CreamSocialWeb.SitemapController do
  use CreamSocialWeb, :controller
  alias CreamSocial.Places
  alias CreamSocial.Events

  def index(conn, _params) do
    # Get all public places and events for sitemap
    places = Places.list_places(%{status: "active"})
    events = Events.discover_events(%{status: "active", upcoming: false})
    
    # Generate sitemap URLs
    place_urls = Enum.map(places, fn place ->
      %{
        url: url(~p"/places/#{place.id}"),
        lastmod: place.updated_at,
        priority: if(place.featured, do: "0.8", else: "0.7"),
        changefreq: "weekly"
      }
    end)
    
    event_urls = Enum.map(events, fn event ->
      %{
        url: url(~p"/events/#{event.id}"),
        lastmod: event.updated_at,
        priority: if(event.featured, do: "0.8", else: "0.7"),
        changefreq: "daily"
      }
    end)
    
    # Static pages
    static_urls = [
      %{
        url: url(~p"/"),
        lastmod: DateTime.utc_now(),
        priority: "1.0",
        changefreq: "daily"
      },
      %{
        url: url(~p"/stream"),
        lastmod: DateTime.utc_now(), 
        priority: "0.9",
        changefreq: "hourly"
      }
    ]
    
    all_urls = static_urls ++ place_urls ++ event_urls
    
    conn
    |> put_resp_content_type("application/xml")
    |> render("index.xml", urls: all_urls)
  end
end