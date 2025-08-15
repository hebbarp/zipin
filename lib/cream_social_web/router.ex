defmodule CreamSocialWeb.Router do
  use CreamSocialWeb, :router
  import Phoenix.Controller

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CreamSocialWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :require_authenticated_user do
    plug :ensure_authenticated
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CreamSocialWeb do
    pipe_through :browser

    live "/", LandingLive, :index
    get "/home", PageController, :home
    
    # Public pages - anyone can view content
    live "/stream", StreamLive.Index, :index
    live "/stream/:id", StreamLive.Show, :show
    live "/places/:id", PlaceLive, :show
    live "/events/:id", EventLive, :show
    live "/profile/:id", ProfileLive.Show, :show
    live "/users/:user_id/followers", FollowersLive.Index, :index
    live "/users/:user_id/following", FollowingLive.Index, :index
    
    # SEO and crawling support
    get "/sitemap.xml", SitemapController, :index
    
    # Authentication routes
    get "/auth/login", AuthController, :login
    get "/auth/register", AuthController, :register
    post "/auth/session", AuthController, :create_session
    post "/auth/register", AuthController, :create_user
    delete "/auth/logout", AuthController, :delete_session
  end

  scope "/", CreamSocialWeb do
    pipe_through [:browser, :require_authenticated_user]

    # Private user-specific pages
    live "/bookmarks", BookmarksLive.Index, :index
    live "/messages", MessagesLive.Index, :index
    live "/messages/:user_id", MessagesLive.Index, :chat
    live "/settings", SettingsLive.Index, :index
  end

  defp fetch_current_user(conn, _opts) do
    user_token = get_session(conn, :user_token)
    user = user_token && CreamSocial.Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: "/auth/login")
      |> halt()
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", CreamSocialWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:zipin, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CreamSocialWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
