defmodule CreamSocial.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string, null: false
      add :description, :text
      add :slug, :string, null: false
      add :color, :string
      add :icon, :string
      add :active, :boolean, default: true

      timestamps()
    end

    create unique_index(:categories, [:slug])
    create index(:categories, [:active])
  end
end
