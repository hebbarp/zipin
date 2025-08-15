defmodule CreamSocial.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :zipin

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed do
    load_app()
    # Run the main seed script
    seed_script = Path.join([Application.app_dir(@app, "priv"), "repo", "seeds.exs"])
    if File.exists?(seed_script) do
      Code.eval_file(seed_script)
    end
    
    # Also run cities seed script
    cities_seed_script = Path.join([Application.app_dir(@app, "priv"), "repo", "seeds_cities_events.exs"])
    if File.exists?(cities_seed_script) do
      Code.eval_file(cities_seed_script)
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
