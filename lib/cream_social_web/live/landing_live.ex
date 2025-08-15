defmodule CreamSocialWeb.LandingLive do
  use CreamSocialWeb, :live_view

  def mount(_params, _session, socket) do
    socket = 
      socket
      |> assign(:current_user, nil)
      |> assign(:page_title, "ZipIn - Bangalore's Hyperlocal Social Platform")
      |> assign(:bangalore_stats, get_bangalore_stats())
      |> assign(:featured_areas, get_featured_areas())
      |> assign(:upcoming_cities, get_upcoming_cities())
      |> assign(:sample_posts, get_sample_posts())
      |> assign(:sample_places, get_sample_places())
      |> assign(:sample_events, get_sample_events())

    {:ok, socket}
  end

  def handle_event("join_waitlist", %{"email" => _email}, socket) do
    # TODO: Store email in waitlist
    socket = put_flash(socket, :info, "🎉 You're on the list! We'll notify you when your area launches.")
    {:noreply, socket}
  end

  def handle_event("explore_app", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/explore")}
  end

  defp get_bangalore_stats do
    %{
      places: 100,
      events: 25,
      areas: 12,
      users: 150
    }
  end

  defp get_featured_areas do
    [
      %{
        name: "Koramangala", 
        icon: "💻", 
        vibe: "Tech Hub",
        image: "https://images.unsplash.com/photo-1497366216548-37526070297c?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80"
      },
      %{
        name: "Indiranagar", 
        icon: "🍻", 
        vibe: "Nightlife",
        image: "https://images.unsplash.com/photo-1514933651103-005eec06c04b?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80"
      },
      %{
        name: "Whitefield", 
        icon: "🏢", 
        vibe: "IT Corridor",
        image: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80"
      },
      %{
        name: "Jayanagar", 
        icon: "🏛️", 
        vibe: "Heritage",
        image: "https://images.unsplash.com/photo-1605640840605-14ac1855827b?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80"
      },
      %{
        name: "HSR Layout", 
        icon: "🏘️", 
        vibe: "Family Zone",
        image: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80"
      },
      %{
        name: "MG Road", 
        icon: "🛍️", 
        vibe: "Shopping",
        image: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80"
      }
    ]
  end

  defp get_upcoming_cities do
    [
      %{name: "Mumbai", eta: "September 2024", status: "next"},
      %{name: "Delhi", eta: "October 2024", status: "planning"},
      %{name: "Pune", eta: "November 2024", status: "planning"},
      %{name: "Hyderabad", eta: "December 2024", status: "planning"},
      %{name: "Chennai", eta: "January 2025", status: "planning"}
    ]
  end

  defp get_sample_posts do
    [
      %{
        author: "Priya K",
        area: "Koramangala",
        content: "Just discovered this amazing filter coffee place in 5th Block! ☕ The uncle makes it exactly like my grandma used to. Hidden gem alert! 🏆",
        time: "2h ago",
        likes: 23,
        replies: 8
      },
      %{
        author: "Arjun M",
        area: "Indiranagar",
        content: "Toit is packed as usual 🍺 but found this new microbrewery called 'Hop House' nearby. Much quieter and better IPAs! Who's joining tonight?",
        time: "4h ago", 
        likes: 31,
        replies: 12
      },
      %{
        author: "Sneha R",
        area: "Whitefield",
        content: "Phoenix MarketCity has a new co-working space on 3rd floor 💻 Great for remote work days. Fast WiFi, good coffee, and not too crowded!",
        time: "1d ago",
        likes: 18,
        replies: 5
      }
    ]
  end

  defp get_sample_places do
    [
      %{name: "CTR (Central Tiffin Room)", area: "Malleswaram", category: "restaurant", rating: 4.8},
      %{name: "Toit Brewpub", area: "Indiranagar", category: "cafe", rating: 4.6},
      %{name: "Lalbagh Botanical Garden", area: "Jayanagar", category: "attraction", rating: 4.7},
      %{name: "The Humming Tree", area: "Indiranagar", category: "entertainment", rating: 4.5}
    ]
  end

  defp get_sample_events do
    [
      %{name: "Bangalore Blockchain Meetup", area: "Koramangala", date: "Aug 20", attendees: 89},
      %{name: "Sunday Morning Cycling", area: "Cubbon Park", date: "Every Sunday", attendees: 156},
      %{name: "Open Mic Night", area: "Indiranagar", date: "Aug 22", attendees: 34}
    ]
  end
end