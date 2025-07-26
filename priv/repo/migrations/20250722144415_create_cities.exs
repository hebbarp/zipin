defmodule CreamSocial.Repo.Migrations.CreateCities do
  use Ecto.Migration

  def change do
    create table(:cities) do
      add :name, :string, null: false
      add :slug, :string, null: false      # bangalore, mumbai, delhi
      add :state, :string, null: false
      add :country, :string, null: false, default: "India"
      add :timezone, :string, null: false, default: "Asia/Kolkata"
      
      # Localization
      add :primary_language, :string, null: false, default: "en"
      add :supported_languages, {:array, :string}, default: ["en"]
      
      # City configuration
      add :areas, {:array, :string}, default: []
      add :cultural_keywords, {:array, :string}, default: []
      add :hashtags, {:array, :string}, default: []
      
      # Status and metadata
      add :active, :boolean, default: true
      add :launched_at, :utc_datetime
      add :config, :map, default: %{}
      
      timestamps(type: :utc_datetime)
    end

    create unique_index(:cities, [:slug])
    create index(:cities, [:active])
    create index(:cities, [:state])
  end
end
