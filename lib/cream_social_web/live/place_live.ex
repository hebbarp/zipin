defmodule CreamSocialWeb.PlaceLive do
  use CreamSocialWeb, :live_view
  alias CreamSocial.Places
  

  def mount(%{"id" => place_id}, _session, socket) do
    case Places.get_place(place_id) do
      nil ->
        {:ok, 
         socket 
         |> put_flash(:error, "Place not found")
         |> push_navigate(to: ~p"/stream")}
      
      place ->
        # Generate SEO-optimized page data
        seo_data = generate_seo_data(place)
        
        socket = 
          socket
          |> assign(:place, place)
          |> assign(:page_title, "#{place.name} in #{area_display_name(place.area)} - ZipIn")
          |> assign(:meta_description, seo_data.description)
          |> assign(:structured_data, seo_data.structured_data)
          |> assign(:reviews, Places.list_place_reviews(place.id, %{limit: 10}))
        
        {:ok, socket}
    end
  end

  # Generate rich structured data for LLMs and search engines
  defp generate_seo_data(place) do
    description = """
    #{place.name} is a #{place.category} located in #{area_display_name(place.area)}, Bangalore. 
    #{if place.description, do: place.description, else: "A popular local spot recommended by the Bangalore community."}
    #{if place.venue_address, do: "Address: #{place.venue_address}.", else: ""}
    #{if place.phone, do: "Contact: #{place.phone}.", else: ""}
    #{if place.community_rating, do: "Community Rating: #{place.community_rating}/5 stars.", else: ""}
    #{if place.price_range, do: "Price Range: #{String.replace(place.price_range, "_", " ") |> String.capitalize()}.", else: ""}
    Find more amazing places in Bangalore on ZipIn - the hyperlocal community platform.
    """

    # JSON-LD structured data for search engines and LLMs
    structured_data = %{
      "@context" => "https://schema.org",
      "@type" => get_schema_type(place.category),
      "name" => place.name,
      "description" => place.description || "Popular #{place.category} in #{area_display_name(place.area)}, Bangalore",
      "address" => %{
        "@type" => "PostalAddress",
        "addressLocality" => area_display_name(place.area),
        "addressRegion" => "Karnataka", 
        "addressCountry" => "IN"
      },
      "geo" => if(place.latitude && place.longitude, do: %{
        "@type" => "GeoCoordinates",
        "latitude" => place.latitude,
        "longitude" => place.longitude
      }),
      "telephone" => place.phone,
      "url" => place.website,
      "priceRange" => get_price_range_symbol(place.price_range),
      "aggregateRating" => if(place.community_rating, do: %{
        "@type" => "AggregateRating",
        "ratingValue" => place.community_rating,
        "ratingCount" => place.community_total_ratings,
        "bestRating" => 5,
        "worstRating" => 1
      }),
      "amenityFeature" => get_amenities_list(place),
      "isAccessibleForFree" => place.category in ["park", "temple", "monument"],
      "openingHours" => place.hours,
      "image" => place.image_url
    }

    %{
      description: String.trim(description),
      structured_data: structured_data
    }
  end

  defp get_schema_type(category) do
    case category do
      "restaurant" -> "Restaurant"
      "cafe" -> "CafeOrCoffeeShop"
      "attraction" -> "TouristAttraction"
      "shopping" -> "Store"
      "service" -> "LocalBusiness"
      _ -> "LocalBusiness"
    end
  end

  defp get_price_range_symbol(price_range) do
    case price_range do
      "budget" -> "₹"
      "mid_range" -> "₹₹"
      "expensive" -> "₹₹₹"
      _ -> nil
    end
  end

  defp get_amenities_list(place) do
    amenities = []
    
    amenities = if place.wifi_available, do: [%{"@type" => "LocationFeatureSpecification", "name" => "Free WiFi"} | amenities], else: amenities
    amenities = if place.parking_available, do: [%{"@type" => "LocationFeatureSpecification", "name" => "Parking Available"} | amenities], else: amenities
    amenities = if place.wheelchair_accessible, do: [%{"@type" => "LocationFeatureSpecification", "name" => "Wheelchair Accessible"} | amenities], else: amenities
    amenities = if place.outdoor_seating, do: [%{"@type" => "LocationFeatureSpecification", "name" => "Outdoor Seating"} | amenities], else: amenities
    
    amenities
  end

  defp area_display_name(area) do
    area
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
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