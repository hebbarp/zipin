defmodule CreamSocial.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Auto-migrate in production
    if Application.get_env(:zipin, :env) == :prod or System.get_env("MIX_ENV") == "prod" do
      try do
        CreamSocial.Release.migrate()
        CreamSocial.Release.seed()
      rescue
        e -> 
          IO.puts("Migration/seeding error: #{inspect(e)}")
      end
    end
    
    children = [
      CreamSocialWeb.Telemetry,
      CreamSocial.Repo,
      {DNSCluster, query: Application.get_env(:zipin, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CreamSocial.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: CreamSocial.Finch},
      # Start a worker by calling: CreamSocial.Worker.start_link(arg)
      # {CreamSocial.Worker, arg},
      # Start to serve requests, typically the last entry
      CreamSocialWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CreamSocial.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CreamSocialWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
