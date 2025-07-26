defmodule CreamSocial.Repo do
  use Ecto.Repo,
    otp_app: :cream_social,
    adapter: Ecto.Adapters.Postgres
end
