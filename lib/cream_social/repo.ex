defmodule CreamSocial.Repo do
  # Use PostgreSQL for production, SQLite for dev/test
  @adapter (if Mix.env() == :prod do
    Ecto.Adapters.Postgres
  else
    case Application.compile_env(:cream_social, :database_adapter, :postgres) do
      :postgres -> Ecto.Adapters.Postgres
      :sqlite -> Ecto.Adapters.SQLite3
    end
  end)

  use Ecto.Repo,
    otp_app: :cream_social,
    adapter: @adapter
end
