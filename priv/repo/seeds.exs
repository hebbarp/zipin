# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CreamSocial.Repo.insert!(%CreamSocial.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias CreamSocial.Repo
alias CreamSocial.Accounts.User
alias CreamSocial.Content.{Post, Category}

# Create some categories
categories = [
  %{name: "Technology", slug: "technology", description: "Tech news and discussions", color: "#3B82F6"},
  %{name: "Business", slug: "business", description: "Business insights and news", color: "#10B981"},
  %{name: "Lifestyle", slug: "lifestyle", description: "Lifestyle and personal content", color: "#F59E0B"},
  %{name: "Entertainment", slug: "entertainment", description: "Entertainment and media", color: "#EF4444"}
]

Enum.each(categories, fn cat_attrs ->
  case Repo.get_by(Category, slug: cat_attrs.slug) do
    nil ->
      %Category{}
      |> Category.changeset(cat_attrs)
      |> Repo.insert!()
    _existing ->
      :ok
  end
end)

# Create a demo user
demo_user = case Repo.get_by(User, email: "demo@creamsocial.com") do
  nil ->
    %User{}
    |> User.registration_changeset(%{
      email: "demo@creamsocial.com",
      password: "DemoPassword123!",
      full_name: "Demo User",
      company: "Cream Social",
      bio: "This is a demo user account for testing the social features.",
      verified: true
    })
    |> Repo.insert!()
  existing ->
    existing
end

# Create engaging Bangalore-focused posts
posts = [
  %{
    content: "🎉 Welcome to ZipIn Bangalore! Just discovered the most amazing filter coffee spot in Koramangala. The owner has been running it for 20 years and the taste is unbeatable! ☕️ #LocalLove #BangaloreCoffee #Koramangala",
    visibility: "public",
    user_id: demo_user.id,
    metadata: %{location: "Koramangala"}
  },
  %{
    content: "Anyone else been to the new rooftop bar at UB City? The view of the city skyline is absolutely stunning! 🌃 Perfect spot for weekend drinks with friends. #BangaloreNightlife #UBCity #WeekendVibes",
    visibility: "public", 
    user_id: demo_user.id,
    metadata: %{location: "UB City"}
  },
  %{
    content: "Cubbon Park at 6 AM hits different 🌳 The morning joggers, fresh air, and that peaceful vibe before the city wakes up. Best way to start the day in Bangalore! #MorningRun #CubbonPark #BangaloreLife",
    visibility: "public",
    user_id: demo_user.id,
    metadata: %{location: "Cubbon Park"}
  },
  %{
    content: "Food coma alert! 🤤 Just had the most incredible dosa at this hidden gem in Jayanagar. 30-year-old family recipe and you can taste the authenticity in every bite. Why do chain restaurants even exist when we have places like this? #AuthenticBangalore #Dosa #Jayanagar",
    visibility: "public",
    user_id: demo_user.id,
    metadata: %{location: "Jayanagar"}
  },
  %{
    content: "Bangalore traffic got you down? 🚗😅 Just spent 2 hours getting from Electronic City to Koramangala. Anyone else think we need more metro lines ASAP? Share your worst traffic stories! #BangaloreTraffic #NammaBangalore #MetroExpansion",
    visibility: "public",
    user_id: demo_user.id
  },
  %{
    content: "The startup energy in Koramangala is infectious! 🚀 Just attended an amazing tech meetup at 91springboard. Met some incredible founders working on AI, fintech, and climate solutions. This city's innovation ecosystem is world-class! #BangaloreStartups #TechMeetup #Innovation",
    visibility: "public",
    user_id: demo_user.id,
    metadata: %{location: "Koramangala"}
  },
  %{
    content: "Weekend vibes: Lalbagh Botanical Garden 🌺 The flower show is spectacular this time of year! Perfect place to escape the city noise and connect with nature. Plus, the Victorian-era glasshouse is a photographer's dream. #Lalbagh #WeekendPlans #NatureInTheCity",
    visibility: "public",
    user_id: demo_user.id,
    metadata: %{location: "Lalbagh"}
  },
  %{
    content: "Indiranagar food crawl complete! 🍽️ Hit up Toit for craft beer, The Humming Tree for live music, and ended at that amazing street food corner near 100ft road. This neighborhood has the perfect mix of trendy and authentic. #IndiRanagar #FoodCrawl #BangaloreEats",
    visibility: "public",
    user_id: demo_user.id,
    metadata: %{location: "Indiranagar"}
  },
  %{
    content: "Hot take: Bangalore has better weather than most international cities 🌤️ While friends in Delhi are melting and Mumbai friends are drowning, we're here with perfect 25°C and a gentle breeze. Never taking this climate for granted! #BangaloreWeather #SiliconValleyOfIndia",
    visibility: "public",
    user_id: demo_user.id
  },
  %{
    content: "Just discovered this coworking space in HSR Layout and it's a game changer! 💻 Super fast internet, unlimited coffee, and the community here is amazing. Meeting fellow entrepreneurs and freelancers is so inspiring. Remote work in Bangalore keeps getting better! #CoworkingLife #HSRLayout #DigitalNomad",
    visibility: "public",
    user_id: demo_user.id,
    metadata: %{location: "HSR Layout"}
  }
]

Enum.each(posts, fn post_attrs ->
  %Post{}
  |> Post.changeset(post_attrs)
  |> Repo.insert!()
end)

IO.puts("Seed data created successfully!")
IO.puts("Demo user: demo@creamsocial.com / DemoPassword123!")

# Places seed data for Bangalore
alias CreamSocial.Places
alias CreamSocial.Places.Place

# Comprehensive Bangalore places data for August 15th launch
places_data = [
  # INDIRANAGAR - Nightlife & Dining Hub
  %{
    name: "Toit Brewpub",
    description: "Craft brewery with great food, known for their fresh beer and wood-fired pizzas. Popular hangout spot in Indiranagar.",
    category: "restaurant",
    subcategory: "fine_dining",
    area: "indiranagar",
    address: "298, 100 Feet Rd, HAL 2nd Stage, Indiranagar",
    pincode: "560038",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    outdoor_seating: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "outdoor_seating", "live_music"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "The Humming Tree",
    description: "Live music venue and bar with great cocktails. Hosts indie bands, open mics, and cultural events.",
    category: "attraction",
    subcategory: "live_music",
    area: "indiranagar",
    address: "12th Main Rd, Indiranagar",
    pincode: "560038",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    outdoor_seating: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "outdoor_seating", "live_music"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Third Wave Coffee Roasters",
    description: "Specialty coffee chain known for fresh roasted beans and minimalist aesthetic. Great for coffee lovers.",
    category: "cafe",
    subcategory: "coffee_shop", 
    area: "indiranagar",
    address: "1131, 12th Main Rd, HAL 2nd Stage, Indiranagar",
    pincode: "560038",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: false,
    accepts_cards: true,
    amenities: ["wifi", "ac"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "The Hole in the Wall Cafe",
    description: "Cozy neighborhood cafe known for excellent breakfast, brunch and coffee. Perfect for working remotely.",
    category: "cafe", 
    subcategory: "coworking_cafe",
    area: "indiranagar",
    address: "16th C Cross, 4th Block, Indiranagar",
    pincode: "560038",
    price_range: "budget",
    wifi_available: true,
    parking_available: false,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "ac", "wheelchair_accessible"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Biere Club",
    description: "Microbrewery with German-style beers and European cuisine. Great for beer enthusiasts.",
    category: "restaurant",
    subcategory: "microbrewery",
    area: "indiranagar",
    address: "CMH Road, Indiranagar",
    pincode: "560038",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    outdoor_seating: false,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },

  # KORAMANGALA - Tech Hub & Startup Paradise
  %{
    name: "Social Offline",
    description: "Popular restaurant and bar with creative cocktails and fusion food. Great ambiance for young crowd.",
    category: "restaurant",
    subcategory: "casual_dining",
    area: "koramangala",
    address: "12th Main Rd, 5th Block, Koramangala",
    pincode: "560095",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    outdoor_seating: false,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "live_music"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "91springboard",
    description: "Premier coworking space for startups and freelancers. Great networking events and community.",
    category: "service",
    subcategory: "coworking_space",
    area: "koramangala",
    address: "Outer Ring Road, 6th Block, Koramangala",
    pincode: "560095",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "wheelchair_accessible"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "The Filter Coffee",
    description: "Traditional South Indian filter coffee house. Authentic taste and old Bangalore charm.",
    category: "cafe",
    subcategory: "traditional_cafe",
    area: "koramangala",
    address: "80 Feet Rd, 4th Block, Koramangala",
    pincode: "560034",
    price_range: "budget",
    wifi_available: false,
    parking_available: false,
    accepts_cards: false,
    amenities: [],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Truffles",
    description: "American diner famous for burgers, milkshakes, and desserts. Student favorite since decades.",
    category: "restaurant",
    subcategory: "casual_dining",
    area: "koramangala",
    address: "St. Marks Road, 5th Block, Koramangala",
    pincode: "560095",
    price_range: "budget",
    wifi_available: true,
    parking_available: false,
    outdoor_seating: false,
    accepts_cards: true,
    amenities: ["wifi", "ac"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "BLR Brewing Company",
    description: "Local microbrewery with craft beers and pub food. Great rooftop seating.",
    category: "restaurant",
    subcategory: "microbrewery",
    area: "koramangala",
    address: "6th Block, Koramangala",
    pincode: "560095",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    outdoor_seating: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "outdoor_seating", "rooftop"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },

  # WHITEFIELD - IT Corridor
  %{
    name: "Phoenix MarketCity",
    description: "Large shopping mall with international brands, food court, and entertainment options.",
    category: "shopping",
    subcategory: "mall",
    area: "whitefield",
    address: "Whitefield Main Road, Mahadevapura",
    pincode: "560048",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "wheelchair_accessible"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "WorkJam Whitefield",
    description: "Modern coworking space with meeting rooms and event spaces. Popular with IT professionals.",
    category: "service",
    subcategory: "coworking_space",
    area: "whitefield",
    address: "ITPL Main Rd, Whitefield",
    pincode: "560066",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "wheelchair_accessible", "meeting_rooms"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Cafe Coffee Day ITPL",
    description: "Popular coffee chain outlet inside ITPL. Convenient for IT professionals.",
    category: "cafe",
    subcategory: "coffee_shop",
    area: "whitefield",
    address: "ITPL, Whitefield",
    pincode: "560066",
    price_range: "budget",
    wifi_available: true,
    parking_available: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Windmills Craftworks",
    description: "Microbrewery and jazz club with live performances. Great beer and musical nights.",
    category: "attraction",
    subcategory: "live_music",
    area: "whitefield",
    address: "Whitefield Main Road",
    pincode: "560066",
    price_range: "expensive",
    wifi_available: true,
    parking_available: true,
    outdoor_seating: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "outdoor_seating", "live_music"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },

  # HSR LAYOUT - Family & Residential
  %{
    name: "The Breakfast Club",
    description: "All-day breakfast cafe with healthy options. Family-friendly with great brunch menu.",
    category: "cafe",
    subcategory: "brunch_cafe",
    area: "hsr_layout",
    address: "27th Main, HSR Layout Sector 2",
    pincode: "560102",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "wheelchair_accessible", "kid_friendly"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "PVR Forum Mall",
    description: "Multiplex cinema with latest movies and premium seating options.",
    category: "attraction",
    subcategory: "cinema",
    area: "hsr_layout",
    address: "Forum Mall, Hosur Road",
    pincode: "560102",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "wheelchair_accessible"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Dyu Art Cafe",
    description: "Art-themed cafe with creative workshops and exhibitions. Great for art lovers.",
    category: "cafe",
    subcategory: "art_cafe",
    area: "hsr_layout",
    address: "14th Main, HSR Layout",
    pincode: "560102",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: false,
    accepts_cards: true,
    amenities: ["wifi", "ac", "art_workshops"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },

  # JAYANAGAR - Heritage & Culture
  %{
    name: "Lalbagh Botanical Garden",
    description: "Famous botanical garden spread across 240 acres with a beautiful glasshouse, perfect for morning walks.",
    category: "attraction",
    subcategory: "garden",
    area: "jayanagar",
    address: "Mavalli, Bengaluru",
    pincode: "560004",
    price_range: "budget",
    wifi_available: false,
    parking_available: true,
    wheelchair_accessible: true,
    outdoor_seating: true,
    accepts_cards: false,
    amenities: ["parking", "wheelchair_accessible"],
    featured: true,
    status: "active", 
    created_by_id: demo_user.id
  },
  %{
    name: "CTR (Central Tiffin Room)",
    description: "Legendary breakfast spot famous for benne dosa and filter coffee. Heritage Bangalore dining.",
    category: "restaurant",
    subcategory: "traditional_restaurant",
    area: "jayanagar",
    address: "Malleswaram",
    pincode: "560003",
    price_range: "budget",
    wifi_available: false,
    parking_available: false,
    accepts_cards: false,
    amenities: ["heritage_restaurant"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Rameshwaram Cafe",
    description: "Popular South Indian restaurant chain known for authentic Karnataka food.",
    category: "restaurant",
    subcategory: "traditional_restaurant",
    area: "jayanagar",
    address: "4th T Block, Jayanagar",
    pincode: "560041",
    price_range: "budget",
    wifi_available: false,
    parking_available: true,
    accepts_cards: true,
    amenities: ["parking"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },

  # MG ROAD - Shopping & Business District
  %{
    name: "UB City Mall",
    description: "Premium shopping mall with luxury brands and fine dining restaurants.",
    category: "shopping",
    subcategory: "luxury_mall",
    area: "mg_road",
    address: "UB City, Vittal Mallya Road",
    pincode: "560001",
    price_range: "expensive",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "wheelchair_accessible", "luxury_shopping"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Skyye Lounge",
    description: "Rooftop lounge with stunning city views and creative cocktails. Premium nightlife experience.",
    category: "attraction",
    subcategory: "rooftop_bar",
    area: "mg_road",
    address: "UB City Mall, Vittal Mallya Road",
    pincode: "560001",
    price_range: "expensive",
    wifi_available: true,
    parking_available: true,
    outdoor_seating: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "outdoor_seating", "city_view", "rooftop"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Cubbon Park",
    description: "Historic park in the heart of the city. Perfect for jogging, walking, and weekend picnics.",
    category: "attraction",
    subcategory: "park",
    area: "mg_road",
    address: "Kasturba Road",
    pincode: "560001",
    price_range: "budget",
    wifi_available: false,
    parking_available: true,
    wheelchair_accessible: true,
    outdoor_seating: true,
    accepts_cards: false,
    amenities: ["parking", "wheelchair_accessible", "jogging_track"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "The Tea Brewery",
    description: "Specialty tea house with extensive tea collection and light snacks. Calm environment for meetings.",
    category: "cafe",
    subcategory: "tea_house",
    area: "mg_road",
    address: "Commercial Street",
    pincode: "560001",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: false,
    accepts_cards: true,
    amenities: ["wifi", "ac"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },

  # MALLESWARAM - Traditional Bangalore
  %{
    name: "Veena Stores",
    description: "Traditional South Indian sweets and snacks shop. Famous for ghee roast and filter coffee.",
    category: "restaurant",
    subcategory: "traditional_restaurant",
    area: "malleswaram",
    address: "Margosa Road, Malleswaram",
    pincode: "560003",
    price_range: "budget",
    wifi_available: false,
    parking_available: false,
    accepts_cards: false,
    amenities: ["heritage_restaurant"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Shivaji Military Hotel",
    description: "Iconic mutton restaurant serving traditional Karnataka non-vegetarian dishes since decades.",
    category: "restaurant",
    subcategory: "traditional_restaurant",
    area: "malleswaram",
    address: "Margosa Road, Malleswaram",
    pincode: "560003",
    price_range: "budget",
    wifi_available: false,
    parking_available: false,
    accepts_cards: false,
    amenities: ["heritage_restaurant"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },

  # ELECTRONIC CITY - Tech Corridor
  %{
    name: "Infiniti Mall",
    description: "Popular shopping mall with retail stores, food court, and entertainment options.",
    category: "shopping",
    subcategory: "mall",
    area: "electronic_city",
    address: "Electronic City Phase 1",
    pincode: "560100",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "wheelchair_accessible"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "WeWork Electronic City",
    description: "Premium coworking space with modern amenities and networking opportunities for tech professionals.",
    category: "service",
    subcategory: "coworking_space",
    area: "electronic_city",
    address: "Electronic City Phase 2",
    pincode: "560100",
    price_range: "expensive",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "wheelchair_accessible", "meeting_rooms"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },

  # RAJAJINAGAR - Emerging Area
  %{
    name: "Orion Mall",
    description: "Large shopping mall with multiplex, food court, and brand stores. Popular weekend destination.",
    category: "shopping",
    subcategory: "mall",
    area: "rajajinagar",
    address: "Dr. Rajkumar Road, Rajajinagar",
    pincode: "560010",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "wheelchair_accessible"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },

  # SARJAPUR ROAD - Growing IT Hub
  %{
    name: "Innovative Multiplex",
    description: "Modern movie theater with comfortable seating and latest sound technology.",
    category: "attraction",
    subcategory: "cinema",
    area: "sarjapur",
    address: "Marathahalli-Sarjapur Outer Ring Road",
    pincode: "560035",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "wheelchair_accessible"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },

  # BANASHANKARI - South Bangalore
  %{
    name: "Banashankari Temple",
    description: "Famous Hindu temple dedicated to Goddess Banashankari. Important cultural and religious site.",
    category: "attraction",
    subcategory: "temple",
    area: "banashankari",
    address: "Banashankari Temple Road",
    pincode: "560050",
    price_range: "budget",
    wifi_available: false,
    parking_available: true,
    wheelchair_accessible: false,
    accepts_cards: false,
    amenities: ["parking"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },

  # RT NAGAR - North Bangalore
  %{
    name: "Lumbini Gardens",
    description: "Lake-side park with boating facilities and evening entertainment. Great for family outings.",
    category: "attraction",
    subcategory: "park",
    area: "rt_nagar",
    address: "Hebbal Lake, RT Nagar",
    pincode: "560024",
    price_range: "budget",
    wifi_available: false,
    parking_available: true,
    outdoor_seating: true,
    accepts_cards: true,
    amenities: ["parking", "boating", "family_friendly"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },

  # ADDITIONAL POPULAR SPOTS ACROSS BANGALORE
  %{
    name: "Big Brewsky",
    description: "Massive microbrewery with outdoor seating, live music, and extensive food menu.",
    category: "restaurant",
    subcategory: "microbrewery",
    area: "sarjapur",
    address: "Sarjapur Road",
    pincode: "560035",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    outdoor_seating: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "outdoor_seating", "live_music"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Plan B",
    description: "Popular club and bar with DJs and dance floor. Great nightlife spot for young crowd.",
    category: "attraction",
    subcategory: "nightclub",
    area: "mg_road",
    address: "Residency Road",
    pincode: "560025",
    price_range: "expensive",
    wifi_available: true,
    parking_available: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "dance_floor"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "ISKCON Temple",
    description: "Beautiful temple complex with spiritual activities, cultural programs, and peaceful atmosphere.",
    category: "attraction",
    subcategory: "temple",
    area: "rajajinagar",
    address: "Hare Krishna Hill, Chord Road",
    pincode: "560010",
    price_range: "budget",
    wifi_available: false,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: false,
    amenities: ["parking", "wheelchair_accessible"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Wonderla",
    description: "Popular amusement park with thrilling rides and water attractions. Great for family fun.",
    category: "attraction",
    subcategory: "amusement_park",
    area: "bidadi",
    address: "Mysore Road, Bidadi",
    pincode: "562109",
    price_range: "expensive",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "wheelchair_accessible", "family_friendly"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Nandi Hills",
    description: "Historic hill station near Bangalore, perfect for sunrise views and weekend getaways.",
    category: "attraction",
    subcategory: "hill_station",
    area: "nandi_hills",
    address: "Nandi Hills, Chikkaballapur District",
    pincode: "562103",
    price_range: "budget",
    wifi_available: false,
    parking_available: true,
    outdoor_seating: true,
    accepts_cards: false,
    amenities: ["parking", "trekking", "sunrise_point"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Bangalore Palace",
    description: "Historic palace with Tudor-style architecture and beautiful gardens. Heritage tourism site.",
    category: "attraction",
    subcategory: "palace",
    area: "vasanth_nagar",
    address: "Palace Road, Vasanth Nagar",
    pincode: "560052",
    price_range: "mid_range",
    wifi_available: false,
    parking_available: true,
    wheelchair_accessible: false,
    accepts_cards: true,
    amenities: ["parking", "heritage_site"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "The Leela Palace",
    description: "Luxury hotel with fine dining restaurants and premium spa services. High-end hospitality.",
    category: "restaurant",
    subcategory: "fine_dining",
    area: "mg_road",
    address: "23, Old Airport Road",
    pincode: "560008",
    price_range: "expensive",
    wifi_available: true,
    parking_available: true,
    wheelchair_accessible: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "wheelchair_accessible", "spa"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Gufha Restaurant",
    description: "Cave-themed restaurant with unique ambiance and North Indian cuisine. Experience dining in a cave.",
    category: "restaurant",
    subcategory: "theme_restaurant",
    area: "koramangala",
    address: "Koramangala 4th Block",
    pincode: "560034",
    price_range: "mid_range",
    wifi_available: true,
    parking_available: true,
    accepts_cards: true,
    amenities: ["wifi", "parking", "ac", "unique_theme"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Ulsoor Lake",
    description: "Scenic lake in the heart of the city with boating facilities and walking paths.",
    category: "attraction",
    subcategory: "lake",
    area: "ulsoor",
    address: "Ulsoor",
    pincode: "560042",
    price_range: "budget",
    wifi_available: false,
    parking_available: true,
    outdoor_seating: true,
    accepts_cards: false,
    amenities: ["parking", "boating", "jogging_track"],
    featured: false,
    status: "active",
    created_by_id: demo_user.id
  },
  %{
    name: "Vidhana Soudha",
    description: "Iconic government building and symbol of Bangalore. Beautiful architecture and historical importance.",
    category: "attraction",
    subcategory: "government_building",
    area: "mg_road",
    address: "Dr. Ambedkar Veedhi",
    pincode: "560001",
    price_range: "budget",
    wifi_available: false,
    parking_available: false,
    wheelchair_accessible: false,
    accepts_cards: false,
    amenities: ["heritage_site"],
    featured: true,
    status: "active",
    created_by_id: demo_user.id
  }
]

# Insert places if they don't exist
Enum.each(places_data, fn place_attrs ->
  case Repo.get_by(Place, name: place_attrs.name) do
    nil ->
      case Places.create_place(place_attrs) do
        {:ok, place} ->
          IO.puts("Created place: #{place.name}")
        {:error, changeset} ->
          IO.puts("Failed to create place #{place_attrs.name}: #{inspect(changeset.errors)}")
      end
    _place ->
      IO.puts("Place #{place_attrs.name} already exists")
  end
end)

IO.puts("Sample places seeded successfully!")
